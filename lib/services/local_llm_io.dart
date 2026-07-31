import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'local_llm_helper.dart';
import 'gguf_validator.dart';

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
  final AsyncLock _lock = AsyncLock();

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
      ];
      for (final lib in libs) {
        try {
          DynamicLibrary.open(lib);
          debugPrint('[LocalMind] Successfully preloaded library: $lib');
        } catch (e) {
          debugPrint('[LocalMind] Preload note for $lib: $e');
        }
      }
    }
    _librariesPreloaded = true;
  }

  int _calculateOptimalThreads() {
    try {
      final cores = Platform.numberOfProcessors;
      // Reserve at least 1 core for OS/UI, min 1, max 4 threads for mobile safety
      final threads = (cores > 2) ? (cores - 1) : 1;
      return threads.clamp(1, 4);
    } catch (_) {
      return 2;
    }
  }

  int _calculateOptimalContextSize(int fileSize) {
    // If file is > 2GB (approx 2147483648 bytes), scale nCtx down to 1024 to save native RAM on Android
    if (fileSize > 2000 * 1024 * 1024) {
      return 1024;
    }
    return 2048;
  }

  @override
  Future<void> loadModel(String modelPath) async {
    return _lock.run(() async {
      await _loadModelInternal(modelPath);
    });
  }

  Future<void> _loadModelInternal(String modelPath) async {
    if (_modelPath == modelPath && _llamaParent != null) {
      debugPrint("[LocalMind] Model already loaded at: $modelPath");
      return;
    }

    if (_llamaParent != null) {
      await _unloadModelInternal();
    }

    final startTime = DateTime.now();
    debugPrint("[LocalMind] Step 1/4: Validating GGUF model binary at path: $modelPath");

    // 1. Verify GGUF header & file integrity
    final validation = await GgufValidator.validateFile(modelPath);
    if (!validation.isValid) {
      debugPrint("[LocalMind] [CRITICAL ERROR] Invalid GGUF model: ${validation.error}");
      throw Exception("Invalid GGUF model binary: ${validation.error}");
    }

    debugPrint("[LocalMind] Step 2/4: GGUF Header valid. Version: ${validation.version}, Tensors: ${validation.tensorCount}, Size: ${(validation.fileSize / (1024*1024)).toStringAsFixed(1)} MB");

    // 2. Preload Libraries safely
    _preloadLibraries();

    // 3. Compute dynamic thread count and context size
    final nThreads = _calculateOptimalThreads();
    final nCtx = _calculateOptimalContextSize(validation.fileSize);

    debugPrint("[LocalMind] Step 3/4: Configuring llama.cpp backend - nThreads=$nThreads, nCtx=$nCtx, nGpuLayers=0 (CPU backend)");

    try {
      final loadCommand = LlamaLoad(
        path: modelPath,
        modelParams: ModelParams()..nGpuLayers = 0,
        contextParams: ContextParams()
          ..nCtx = nCtx
          ..nThreads = nThreads
          ..nBatch = 512,
        samplingParams: SamplerParams(),
      );

      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init();
      _modelPath = modelPath;

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint("[LocalMind] Step 4/4: llama.cpp engine initialized successfully in ${elapsedMs}ms.");
    } catch (e, stackTrace) {
      debugPrint("[LocalMind] [CRITICAL ERROR] Failed to initialize llama.cpp native engine: $e");
      debugPrint("[LocalMind] Stack trace: $stackTrace");
      _llamaParent = null;
      _modelPath = null;
      throw Exception("Failed to initialize local LLM engine ($e)");
    }
  }

  @override
  Future<String> generateResponse(String prompt, String modelName, String modelPath) async {
    return _lock.run(() async {
      return await _generateResponseInternal(prompt, modelName, modelPath);
    });
  }

  Future<String> _generateResponseInternal(String prompt, String modelName, String modelPath) async {
    if (_llamaParent == null || _modelPath != modelPath) {
      await _loadModelInternal(modelPath);
    }

    if (_llamaParent == null) {
      throw Exception("Local model engine is not initialized.");
    }

    final startTime = DateTime.now();
    debugPrint("[LocalMind] Inference Start - Prompt length: ${prompt.length} chars. Model: $modelName");

    final completer = Completer<String>();
    final StringBuffer responseBuffer = StringBuffer();
    StreamSubscription<String>? subscription;

    subscription = _llamaParent!.stream.listen(
      (token) {
        responseBuffer.write(token);
      },
      onError: (error, stackTrace) {
        debugPrint("[LocalMind] Error during native token streaming: $error");
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(responseBuffer.toString().trim());
        }
      },
      cancelOnError: true,
    );

    try {
      _llamaParent!.sendPrompt(prompt);

      // Enforce 60-second timeout on local inference to prevent infinite freezes
      final response = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint("[LocalMind] [TIMEOUT] Inference timed out after 60 seconds.");
          if (responseBuffer.isNotEmpty) {
            return responseBuffer.toString().trim();
          }
          throw TimeoutException("Local inference timed out.");
        },
      );

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint("[LocalMind] Inference Completed in ${elapsedMs}ms. Output length: ${response.length} chars.");

      await subscription.cancel();
      return response;
    } catch (e, stackTrace) {
      await subscription.cancel();
      debugPrint("[LocalMind] Exception in local response generation: $e");
      debugPrint("[LocalMind] Stack trace: $stackTrace");
      rethrow;
    }
  }

  @override
  Future<void> unloadModel() async {
    return _lock.run(() async {
      await _unloadModelInternal();
    });
  }

  Future<void> _unloadModelInternal() async {
    if (_llamaParent != null) {
      debugPrint("[LocalMind] Unloading local LLM model from memory...");
      try {
        _llamaParent!.dispose();
      } catch (e) {
        debugPrint("[LocalMind] Error disposing LlamaParent: $e");
      }
      _llamaParent = null;
    }
    _modelPath = null;
    debugPrint("[LocalMind] Model unloaded.");
  }

  @override
  bool get isModelLoaded => _llamaParent != null;
}
