// ignore_for_file: dead_code
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model.dart';
import 'gguf_validator.dart';
import 'device_info_helper.dart';

typedef ModelDownloadProgressCallback = void Function(
  double progress,
  int receivedBytes,
  int totalBytes,
  double speedMBs,
);

class ModelManager {
  final Dio _dio = Dio();
  static const String _installedModelsKey = 'installed_model_ids';

  // Standardized curated GGUF models optimized for on-device mobile inference
  final List<AIModel> availableModels = [
    AIModel(
      id: 'gemma3_1b',
      name: 'Gemma 3 1B',
      description:
          "Google’s lightweight 1B parameter text model, designed for efficient deployment and strong instruction following.",
      downloadUrl:
          "https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf",
      fileName: "gemma-3-1b-it-Q4_K_M.gguf",
      size: "0.80 GB",
      fileSizeBytes: 806 * 1024 * 1024,
      ramRequired: "2.0 GB RAM",
      minimumRamGB: 2.0,
      recommendedRamGB: 3.0,
      quantization: "Q4_K_M",
      contextLength: 32768,
      chatTemplate: "gemma",
      capabilities: [
        'Fast Inference',
        'Question Answering',
        'Summarization',
        'Reasoning',
        'Conversational AI'
      ],
      isRecommended: true,
    ),
    AIModel(
      id: 'qwen2.5_1.5b',
      name: 'Qwen 2.5 1.5B',
      description:
          "Alibaba's compact 1.5B instruction-tuned model with strong coding, mathematics, instruction following, and multilingual capabilities.",
      downloadUrl:
          "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
      fileName: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
      size: "1.0 GB",
      fileSizeBytes: 1120 * 1024 * 1024,
      ramRequired: "2.5 GB RAM",
      minimumRamGB: 2.0,
      recommendedRamGB: 3.5,
      quantization: "Q4_K_M",
      contextLength: 2048,
      chatTemplate: "chatml",
      capabilities: [
        'Coding',
        'Math & Logic',
        'Multilingual',
        'Instruction Following'
      ],
    ),
    AIModel(
      id: 'qwen2.5_3b',
      name: 'Qwen 2.5 3B',
      description:
          "A capable 3B model for reasoning, coding, and complex tasks.",
      downloadUrl:
          "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
      fileName: "qwen2.5-3b-instruct-q4_k_m.gguf",
      size: "2.1 GB",
      fileSizeBytes: 2180 * 1024 * 1024,
      ramRequired: "3.8 GB RAM",
      minimumRamGB: 3.5,
      recommendedRamGB: 5.0,
      quantization: "Q4_K_M",
      contextLength: 32768,
      chatTemplate: "chatml",
      capabilities: ['Advanced Reasoning', 'Complex Tasks', 'Code Generation'],
    ),
    AIModel(
      id: 'llama3.2_1b',
      name: 'Llama 3.2 1B',
      description:
          "Meta's compact 1B model for fast, efficient text generation.",
      downloadUrl:
          "https://huggingface.co/lmstudio-community/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      fileName: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      size: "0.8 GB",
      fileSizeBytes: 808 * 1024 * 1024,
      ramRequired: "1.8 GB RAM",
      minimumRamGB: 1.8,
      recommendedRamGB: 2.8,
      quantization: "Q4_K_M",
      contextLength: 2048,
      chatTemplate: "llama3",
      capabilities: ['Summarization', 'Low Latency', 'Edge Friendly'],
    ),
    AIModel(
      id: 'smollm2_1.7b',
      name: 'SmolLM2 1.7B',
      description:
          "Hugging Face's compact high-performance reasoning model trained on curated educational data.",
      downloadUrl:
          "https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf",
      fileName: "smollm2-1.7b-instruct-q4_k_m.gguf",
      size: "1.0 GB",
      fileSizeBytes: 1060 * 1024 * 1024,
      ramRequired: "2.2 GB RAM",
      minimumRamGB: 2.0,
      recommendedRamGB: 3.0,
      quantization: "Q4_K_M",
      contextLength: 2048,
      chatTemplate: "chatml",
      capabilities: ['Educational Q&A', 'Reasoning', 'Compact Footprint'],
    ),
    AIModel(
      id: 'phi3.5_mini',
      name: 'Phi-3.5 Mini (3.8B)',
      description:
          "Microsoft's state-of-the-art small language model with high benchmark scores in science and logic.",
      downloadUrl:
          "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf",
      fileName: "Phi-3.5-mini-instruct-Q4_K_M.gguf",
      size: "2.3 GB",
      fileSizeBytes: 2350 * 1024 * 1024,
      ramRequired: "4.2 GB RAM",
      minimumRamGB: 4.0,
      recommendedRamGB: 6.0,
      quantization: "Q4_K_M",
      contextLength: 2048,
      chatTemplate: "phi3",
      capabilities: ['Science & Math', 'Deep Reasoning', 'Long Context'],
    ),
  ];

  CancelToken? _cancelToken;

  Future<String> get _modelsDir async {
    if (kIsWeb) return 'web_models';
    final docs = await getApplicationDocumentsDirectory();
    final path = '${docs.path}/models';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  /// Checks whether device has sufficient free storage space (Model size + 500MB safety buffer)
  Future<bool> hasSufficientStorage(int requiredBytes) async {
    if (kIsWeb) return true;
    try {
      final specs = await DeviceInfoHelper.getDeviceSpecs();
      final freeBytes = specs.freeStorageGB * 1024 * 1024 * 1024;
      const safetyBufferBytes = 500 * 1024 * 1024; // 500 MB buffer
      if (freeBytes < (requiredBytes + safetyBufferBytes)) {
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Downloads a GGUF model with streaming directly to a temporary `.download` file.
  Future<void> downloadModel(
    AIModel model,
    ModelDownloadProgressCallback onProgress, {
    bool resume = false,
  }) async {
    if (kIsWeb) {
      _cancelToken = CancelToken();
      double startP = resume ? model.downloadProgress : 0.0;
      for (double p = startP; p <= 1.0; p += 0.05) {
        if (_cancelToken?.isCancelled == true) {
          throw DioException(
            requestOptions: RequestOptions(path: model.downloadUrl),
            message: 'Cancelled by user',
            type: DioExceptionType.cancel,
          );
        }
        await Future.delayed(const Duration(milliseconds: 80));
        onProgress(
            p, (p * model.fileSizeBytes).round(), model.fileSizeBytes, 15.0);
      }
      await _saveInstalledStatus(model.id, true);
      return;
    }

    // Check disk storage availability before allocating resources
    final hasSpace = await hasSufficientStorage(model.fileSizeBytes);
    if (!hasSpace) {
      throw Exception(
        "Insufficient disk space. Please ensure you have at least ${(model.fileSizeBytes / (1024 * 1024 * 1024) + 0.5).toStringAsFixed(1)} GB of free storage.",
      );
    }

    _cancelToken = CancelToken();
    final dirPath = await _modelsDir;
    final finalFilePath = '$dirPath/${model.fileName}';
    final tempFilePath = '$dirPath/${model.fileName}.download';
    final tempFile = File(tempFilePath);
    final finalFile = File(finalFilePath);

    // If already finalized, do nothing
    if (await finalFile.exists() && !resume) {
      final valid = await GgufValidator.validateFile(finalFilePath);
      if (valid.isValid) {
        await _saveInstalledStatus(model.id, true);
        return;
      } else {
        await finalFile.delete();
      }
    }

    if (!resume && await tempFile.exists()) {
      await tempFile.delete();
    }

    int startBytes = 0;
    if (resume && await tempFile.exists()) {
      startBytes = await tempFile.length();
    }

    RandomAccessFile? fileAccess;
    DateTime lastSpeedSampleTime = DateTime.now();
    int lastSampleBytes = startBytes;
    double currentSpeedMBs = 0.0;

    try {
      debugPrint(
          "[LocalMind] Starting streamed download from: ${model.downloadUrl}");
      final response = await _dio.get<ResponseBody>(
        model.downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: startBytes > 0 ? {'range': 'bytes=$startBytes-'} : null,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
        cancelToken: _cancelToken,
      );

      final int statusCode = response.statusCode ?? 200;
      final bool isRange = statusCode == 206;

      if (!isRange && startBytes > 0) {
        startBytes = 0;
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      fileAccess =
          await tempFile.open(mode: isRange ? FileMode.append : FileMode.write);

      final totalBytesInResponse =
          int.tryParse(response.headers.value('content-length') ?? '') ?? -1;
      final totalBytes = (totalBytesInResponse != -1)
          ? (totalBytesInResponse + startBytes)
          : model.fileSizeBytes;

      int receivedBytes = startBytes;

      await for (final chunk in response.data!.stream) {
        if (_cancelToken?.isCancelled == true) {
          break;
        }

        await fileAccess.writeFrom(chunk);
        receivedBytes += chunk.length;

        final now = DateTime.now();
        final msDiff = now.difference(lastSpeedSampleTime).inMilliseconds;
        if (msDiff >= 800) {
          final bytesDiff = receivedBytes - lastSampleBytes;
          currentSpeedMBs = (bytesDiff / (1024 * 1024)) / (msDiff / 1000.0);
          lastSpeedSampleTime = now;
          lastSampleBytes = receivedBytes;
        }

        final progress = (totalBytes > 0)
            ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
            : 0.0;
        onProgress(progress, receivedBytes, totalBytes, currentSpeedMBs);
      }

      if (_cancelToken?.isCancelled == true) {
        throw DioException(
          requestOptions: RequestOptions(path: model.downloadUrl),
          message: _cancelToken?.cancelError?.toString() ?? 'Cancelled by user',
          type: DioExceptionType.cancel,
        );
      }

      await fileAccess.close();
      fileAccess = null;

      // 1. Validate GGUF Magic Header & Tensor Integrity
      debugPrint("[LocalMind] Validating downloaded GGUF file header...");
      final validation = await GgufValidator.validateFile(tempFilePath);
      if (!validation.isValid) {
        debugPrint(
            "[LocalMind] GGUF validation failed for ${model.name}: ${validation.error}");
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        await _saveInstalledStatus(model.id, false);
        throw Exception(
            "Downloaded file is corrupt or invalid GGUF format: ${validation.error}");
      }

      // 2. Optional SHA-256 Checksum Validation
      if (model.sha256 != null && model.sha256!.isNotEmpty) {
        debugPrint(
            "[LocalMind] Computing SHA-256 checksum for verification...");
        final stream = tempFile.openRead();
        final digest = await sha256.bind(stream).first;
        if (digest.toString().toLowerCase() != model.sha256!.toLowerCase()) {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          await _saveInstalledStatus(model.id, false);
          throw Exception(
              "SHA-256 verification failed. File integrity compromised.");
        }
        debugPrint("[LocalMind] SHA-256 checksum matched successfully.");
      }

      // 3. Atomic Rename from .download to final model.gguf
      debugPrint("[LocalMind] Atomic rename from temp file to $finalFilePath");
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFilePath);

      await _saveInstalledStatus(model.id, true);
      debugPrint(
          "[LocalMind] Model ${model.name} successfully verified and installed.");
    } catch (e) {
      if (fileAccess != null) {
        try {
          await fileAccess.close();
        } catch (_) {}
      }

      if (e is DioException && CancelToken.isCancel(e)) {
        final reason = e.error?.toString() ?? e.message ?? '';
        if (reason == 'pause') {
          // Keep temporary file for resumption
          rethrow;
        }
      }

      // On fatal error or cancel, delete temp file
      if (await tempFile.exists() &&
          (e is! DioException || !CancelToken.isCancel(e))) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  void cancelDownload({String? reason}) {
    _cancelToken?.cancel(reason ?? 'Cancelled by user');
  }

  Future<void> deleteModel(String modelId) async {
    final index = availableModels.indexWhere((m) => m.id == modelId);
    if (index == -1) return;
    final model = availableModels[index];

    if (!kIsWeb) {
      final dirPath = await _modelsDir;
      final finalFile = File('$dirPath/${model.fileName}');
      final tempFile = File('$dirPath/${model.fileName}.download');

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
    await _saveInstalledStatus(modelId, false);
  }

  Future<bool> isModelInstalled(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    final installedIds = prefs.getStringList(_installedModelsKey) ?? [];
    if (!installedIds.contains(modelId)) return false;

    if (kIsWeb) return true;

    final path = await getModelPath(modelId);
    if (path == null) return false;
    final file = File(path);
    if (!await file.exists()) return false;

    final validation = await GgufValidator.validateFile(path);
    if (!validation.isValid) {
      debugPrint(
          "[LocalMind] Model integrity verification failed for $modelId. Cleaning up.");
      try {
        await file.delete();
      } catch (_) {}
      await _saveInstalledStatus(modelId, false);
      return false;
    }
    return true;
  }

  Future<String?> getModelPath(String modelId) async {
    final index = availableModels.indexWhere((m) => m.id == modelId);
    if (index == -1) return null;
    final model = availableModels[index];
    final dirPath = await _modelsDir;
    return '$dirPath/${model.fileName}';
  }

  Future<List<AIModel>> getInstalledModels() async {
    final List<AIModel> list = [];
    for (var model in availableModels) {
      if (await isModelInstalled(model.id)) {
        list.add(model.copyWith(installed: true, isDownloaded: true));
      }
    }
    return list;
  }

  Future<void> _saveInstalledStatus(String modelId, bool installed) async {
    final prefs = await SharedPreferences.getInstance();
    final installedIds = prefs.getStringList(_installedModelsKey) ?? [];
    if (installed) {
      if (!installedIds.contains(modelId)) {
        installedIds.add(modelId);
      }
    } else {
      installedIds.remove(modelId);
    }
    await prefs.setStringList(_installedModelsKey, installedIds);
  }
}
