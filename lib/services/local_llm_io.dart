import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_llm_helper.dart';
import 'gguf_validator.dart';
import 'device_info_helper.dart';
import 'settings_service.dart';

LocalLLM getPlatformLLM() => LocalLLMIO();

class AsyncLock {
  Future<void>? _lastOperation;

  Future<T> run<T>(Future<T> Function() action) async {
    final previous = _lastOperation;
    final completer = Completer<void>();
    _lastOperation = completer.future;

    if (previous != null) {
      try {
        await previous;
      } catch (_) {}
    }

    try {
      return await action();
    } finally {
      completer.complete();
    }
  }
}

class LocalLLMIO implements LocalLLM {
  LlamaParent? _llamaParent;
  String? _modelPath;
  bool _librariesPreloaded = false;
  bool _isGenerating = false;
  StreamSubscription<String>? _activeSubscription;
  final AsyncLock _lock = AsyncLock();

  // Diagnostic metrics
  int lastInferenceDurationMs = 0;
  int lastTokenCount = 0;
  String lastFirstTokenTime = '0ms';
  String? lastError;
  String lastCrashMarker = 'IDLE';
  int activeContextSize = 2048;
  int activeThreadCount = 2;

  static const String _crashMarkerKey = 'last_native_crash_marker';

  Future<void> _setCrashMarker(String marker) async {
    lastCrashMarker = marker;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_crashMarkerKey, marker);
      debugPrint("[LLM_CRASH_MARKER] $marker");
    } catch (_) {}
  }

  void _preloadLibraries() {
    if (_librariesPreloaded) return;
    if (Platform.isAndroid) {
      final libs = [
        'libc++_shared.so',
        'libomp.so',
        'libggml-base.so',
        'libggml.so',
        'libggml-cpu.so',
        'libllama.so',
        'libmtmd.so',
      ];
      for (final lib in libs) {
        try {
          DynamicLibrary.open(lib);
          debugPrint('[LocalMind] Preloaded library: $lib');
        } catch (e) {
          debugPrint('[LocalMind] Preload note for $lib: $e');
        }
      }
    }
    _librariesPreloaded = true;
  }

  int _calculateOptimalThreads(int requestedThreads) {
    if (requestedThreads > 0) {
      return requestedThreads.clamp(1, 8);
    }
    try {
      final cores = Platform.numberOfProcessors;
      final threads = (cores > 2) ? (cores - 1) : 1;
      return threads.clamp(1, 4);
    } catch (_) {
      return 2;
    }
  }

  int _calculateOptimalContextSize(int fileSize, int requestedCtx) {
    if (requestedCtx > 0) {
      return requestedCtx;
    }
    // Scale nCtx down to 1024 for files > 1.8GB to protect mobile RAM
    if (fileSize > 1800 * 1024 * 1024) {
      return 1024;
    }
    return 2048;
  }

  @override
  Future<void> loadModel(String modelPath, {InferenceSettings? settings}) async {
    return _lock.run(() async {
      await _loadModelInternal(modelPath, settings: settings);
    });
  }

  Future<void> _loadModelInternal(String modelPath, {InferenceSettings? settings}) async {
    if (_modelPath == modelPath && _llamaParent != null) {
      debugPrint("[LLM] ACTIVE_MODEL=$modelPath");
      debugPrint("[LLM] MODEL_LOADED=true (Cached)");
      return;
    }

    await _setCrashMarker("STAGE_MODEL_LOAD_START: $modelPath");

    if (_llamaParent != null) {
      await _unloadModelInternal();
    }

    final modelName = modelPath.split('/').last.split('\\').last;
    debugPrint("[LLM] ACTIVE_MODEL=$modelName");
    final startTime = DateTime.now();

    // 1. Verify GGUF header & file integrity
    await _setCrashMarker("STAGE_GGUF_HEADER_VALIDATE");
    final validation = await GgufValidator.validateFile(modelPath);
    if (!validation.isValid) {
      lastError = "Invalid GGUF model: ${validation.error}";
      await _setCrashMarker("STAGE_GGUF_HEADER_ERROR: ${validation.error}");
      debugPrint("[LLM] [CRITICAL ERROR] Invalid GGUF model: ${validation.error}");
      throw Exception("Invalid GGUF model binary: ${validation.error}");
    }

    // 2. RAM Pre-check Safeguard for Mobile
    await _setCrashMarker("STAGE_RAM_PRECHECK");
    final infSettings = settings ?? InferenceSettings();
    activeThreadCount = _calculateOptimalThreads(infSettings.cpuThreads);
    activeContextSize = _calculateOptimalContextSize(validation.fileSize, infSettings.contextLength);

    try {
      final specs = await DeviceInfoHelper.getDeviceSpecs();
      final availableRamBytes = (specs.totalRamGB - specs.usedRamGB) * 1024 * 1024 * 1024;
      final requiredRamBytes = validation.fileSize + (activeContextSize * 1024 * 4) + (500 * 1024 * 1024);

      if (availableRamBytes < requiredRamBytes) {
        final reqGB = (requiredRamBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
        final availGB = (availableRamBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
        await _setCrashMarker("STAGE_RAM_INSUFFICIENT: req=$reqGB GB, avail=$availGB GB");
        throw Exception("Insufficient RAM to load model safely ($reqGB GB required, ~$availGB GB available). Low-memory safeguard blocked allocation.");
      }
    } catch (e) {
      debugPrint("[LLM] RAM check note: $e");
    }

    // 3. Preload Libraries safely & set target library
    await _setCrashMarker("STAGE_PRELOAD_LIBRARIES");
    _preloadLibraries();
    Llama.libraryPath = Platform.isAndroid ? "libllama.so" : null;

    try {
      await _setCrashMarker("STAGE_CONTEXT_PARAMS_BUILD");
      final samplerParams = SamplerParams()
        ..temp = infSettings.temperature
        ..topP = infSettings.topP
        ..topK = infSettings.topK
        ..penaltyRepeat = infSettings.repeatPenalty;

      final loadCommand = LlamaLoad(
        path: modelPath,
        modelParams: ModelParams()..nGpuLayers = 0, // CPU-only mode for stability
        contextParams: ContextParams()
          ..nCtx = activeContextSize
          ..nThreads = activeThreadCount
          ..nBatch = 512,
        samplingParams: samplerParams,
        verbose: false,
      );

      await _setCrashMarker("STAGE_LLAMA_PARENT_INIT");
      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init();
      _modelPath = modelPath;

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      lastError = null;

      await _setCrashMarker("STAGE_MODEL_READY");
      debugPrint("[LLM] MODEL_LOADED=true");
      debugPrint("[LLM] CONTEXT_CREATED nCtx=$activeContextSize, nThreads=$activeThreadCount, duration=${elapsedMs}ms");
    } catch (e, stackTrace) {
      lastError = e.toString();
      await _setCrashMarker("STAGE_LLAMA_INIT_ERROR: $e");
      debugPrint("[LLM] [CRITICAL ERROR] Failed to initialize llama.cpp native engine: $e");
      debugPrint("[LLM] Stack trace: $stackTrace");
      _llamaParent = null;
      _modelPath = null;
      throw Exception("Failed to initialize local LLM engine ($e)");
    }
  }

  @override
  Stream<String> generateStream(String prompt, String modelName, String modelPath, {InferenceSettings? settings}) async* {
    if (_llamaParent == null || _modelPath != modelPath) {
      await loadModel(modelPath, settings: settings);
    }

    if (_llamaParent == null) {
      throw Exception("Local model engine is not initialized.");
    }

    await _setCrashMarker("STAGE_GENERATION_SUBMIT");
    _isGenerating = true;
    final controller = StreamController<String>();

    final startTime = DateTime.now();
    int tokensCount = 0;
    bool isFirstToken = true;

    debugPrint("[LLM] ACTIVE_MODEL=$modelName");
    debugPrint("[LLM] PROMPT_CREATED length=${prompt.length}");
    debugPrint("[LLM] GENERATION_START");

    StreamSubscription<String>? textSub;
    StreamSubscription<CompletionEvent>? compSub;

    textSub = _llamaParent!.stream.listen(
      (token) {
        if (isFirstToken) {
          isFirstToken = false;
          final firstTokenMs = DateTime.now().difference(startTime).inMilliseconds;
          lastFirstTokenTime = "${firstTokenMs}ms";
          _setCrashMarker("STAGE_FIRST_TOKEN_RECEIVED");
          debugPrint("[LLM] FIRST_TOKEN=${token.trim()} latency=${firstTokenMs}ms");
        }

        tokensCount++;

        if (!controller.isClosed) {
          controller.add(token);
        }
      },
      onError: (error) {
        lastError = error.toString();
        _setCrashMarker("STAGE_STREAM_ERROR: $error");
        debugPrint("[LLM] STREAM_ERROR: $error");
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    compSub = _llamaParent!.completions.listen(
      (event) {
        _isGenerating = false;
        final totalElapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        lastInferenceDurationMs = totalElapsedMs;
        lastTokenCount = tokensCount;

        _setCrashMarker("STAGE_GENERATION_COMPLETE");
        debugPrint("[LLM] EOS");
        debugPrint("[LLM] GENERATION_COMPLETE - $tokensCount tokens in ${totalElapsedMs}ms (${(tokensCount / (totalElapsedMs / 1000.0)).toStringAsFixed(1)} t/s)");

        if (!event.success && event.errorDetails != null) {
          lastError = event.errorDetails;
          if (!controller.isClosed) {
            controller.addError(Exception("Inference error: ${event.errorDetails}"));
          }
        }

        textSub?.cancel();
        compSub?.cancel();
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    try {
      await _setCrashMarker("STAGE_SEND_PROMPT_NATIVE");
      await _llamaParent!.sendPrompt(prompt);
    } catch (e) {
      _isGenerating = false;
      lastError = e.toString();
      await _setCrashMarker("STAGE_SEND_PROMPT_ERROR: $e");
      await textSub.cancel();
      await compSub.cancel();
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }

    yield* controller.stream;
  }

  @override
  Future<String> generateResponse(String prompt, String modelName, String modelPath, {InferenceSettings? settings}) async {
    return _lock.run(() async {
      final buffer = StringBuffer();
      final completer = Completer<String>();

      if (_llamaParent == null || _modelPath != modelPath) {
        await _loadModelInternal(modelPath, settings: settings);
      }

      if (_llamaParent == null) {
        throw Exception("Local model engine is not initialized.");
      }

      await _setCrashMarker("STAGE_RESPONSE_GENERATE_SUBMIT");
      final startTime = DateTime.now();
      int tokensCount = 0;
      bool isFirstToken = true;

      debugPrint("[LLM] ACTIVE_MODEL=$modelName");
      debugPrint("[LLM] PROMPT_CREATED length=${prompt.length}");

      StreamSubscription<String>? textSub;
      StreamSubscription<CompletionEvent>? compSub;

      textSub = _llamaParent!.stream.listen((token) {
        if (isFirstToken) {
          isFirstToken = false;
          final firstTokenMs = DateTime.now().difference(startTime).inMilliseconds;
          lastFirstTokenTime = "${firstTokenMs}ms";
          _setCrashMarker("STAGE_FIRST_TOKEN_RECEIVED");
        }
        tokensCount++;
        buffer.write(token);
      });

      compSub = _llamaParent!.completions.listen((event) {
        textSub?.cancel();
        compSub?.cancel();

        final totalElapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        lastInferenceDurationMs = totalElapsedMs;
        lastTokenCount = tokensCount;

        _setCrashMarker("STAGE_GENERATION_COMPLETE");
        debugPrint("[LLM] EOS");

        if (event.success) {
          if (!completer.isCompleted) {
            completer.complete(buffer.toString().trim());
          }
        } else {
          lastError = event.errorDetails;
          if (!completer.isCompleted) {
            completer.completeError(Exception("Inference error: ${event.errorDetails}"));
          }
        }
      });

      try {
        await _setCrashMarker("STAGE_SEND_PROMPT_NATIVE");
        await _llamaParent!.sendPrompt(prompt);

        final response = await completer.future.timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            textSub?.cancel();
            compSub?.cancel();
            if (buffer.isNotEmpty) {
              return buffer.toString().trim();
            }
            throw TimeoutException("Local inference timed out after 90 seconds.");
          },
        );

        return response;
      } catch (e) {
        await textSub.cancel();
        await compSub.cancel();
        lastError = e.toString();
        await _setCrashMarker("STAGE_RESPONSE_ERROR: $e");
        debugPrint("[LLM] Exception during response generation: $e");
        rethrow;
      }
    });
  }

  @override
  void stopGeneration() {
    if (_isGenerating) {
      _isGenerating = false;
      _activeSubscription?.cancel();
      _activeSubscription = null;
      _setCrashMarker("STAGE_STOP_GENERATION");
      debugPrint("[LLM] User stopped generation.");
    }
  }

  @override
  Future<void> unloadModel() async {
    return _lock.run(() async {
      await _unloadModelInternal();
    });
  }

  Future<void> _unloadModelInternal() async {
    await _setCrashMarker("STAGE_UNLOAD_START");
    stopGeneration();
    if (_llamaParent != null) {
      debugPrint("[LLM] UNLOADING_MODEL: $_modelPath");
      try {
        _llamaParent!.dispose();
      } catch (e) {
        debugPrint("[LLM] Error disposing LlamaParent: $e");
      }
      _llamaParent = null;
    }
    _modelPath = null;
    await _setCrashMarker("IDLE");
    debugPrint("[LLM] MODEL_UNLOADED=true");
  }

  @override
  bool get isModelLoaded => _llamaParent != null;

  @override
  LLMDiagnostics getDiagnostics() {
    final tps = (lastInferenceDurationMs > 0 && lastTokenCount > 0)
        ? (lastTokenCount / (lastInferenceDurationMs / 1000.0))
        : 0.0;

    return LLMDiagnostics(
      activeModelPath: _modelPath,
      isLoaded: isModelLoaded,
      activeContextSize: activeContextSize,
      activeThreadCount: activeThreadCount,
      lastInferenceDurationMs: lastInferenceDurationMs,
      lastTokenCount: lastTokenCount,
      tokensPerSecond: tps,
      lastFirstTokenLatency: lastFirstTokenTime,
      lastError: lastError,
      lastCrashMarker: lastCrashMarker,
    );
  }
}
