// ignore_for_file: dead_code
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model.dart';
import 'gguf_validator.dart';

class ModelManager {
  final Dio _dio = Dio();
  static const String _installedModelsKey = 'installed_model_ids';

  // Available models list (configured with actual GGUF links)
  final List<AIModel> availableModels = [
    AIModel(
      id: 'gemma3_1b',
      name: 'Gemma 3 1B',
      description: "Google's state-of-the-art lightweight model, optimized for mobile efficiency.",
      downloadUrl: "https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf",
      fileName: "gemma-3-1b-it-Q4_K_M.gguf",
      size: "0.9 GB",
      ramRequired: "2 GB RAM",
      quantization: "FP16",
      isRecommended: true,
    ),
    AIModel(
      id: 'qwen3_1.7b',
      name: 'Qwen3 1.7B',
      description: "Alibaba's advanced small-scale bilingual model, featuring strong reasoning.",
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
      fileName: "qwen2.5-1.5b-instruct-q4_k_m.gguf",
      size: "1.3 GB",
      ramRequired: "3 GB RAM",
      quantization: "GGUF",
    ),
    AIModel(
      id: 'llama3.2_1b',
      name: 'Llama 3.2 1B',
      description: "Meta's highly optimized lightweight model, perfect for summarization.",
      downloadUrl: "https://huggingface.co/lmstudio-community/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      fileName: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
      size: "0.9 GB",
      ramRequired: "2 GB RAM",
      quantization: "GGUF",
    ),
    AIModel(
      id: 'smollm2_1.7b',
      name: 'SmolLM2 1.7B',
      description: "Hugging Face's extremely compact reasoning model.",
      downloadUrl: "https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF/resolve/main/smollm2-1.7b-instruct-q4_k_m.gguf",
      fileName: "smollm2-1.7b-instruct-q4_k_m.gguf",
      size: "1.1 GB",
      ramRequired: "3 GB RAM",
      quantization: "GGUF",
    ),
    AIModel(
      id: 'qwen2.5_3b',
      name: 'Qwen 2.5 3B',
      description: "Alibaba's medium-size language model, delivering robust reasoning.",
      downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf",
      fileName: "qwen2.5-3b-instruct-q4_k_m.gguf",
      size: "2.2 GB",
      ramRequired: "4 GB RAM",
      quantization: "GGUF",
    ),
    AIModel(
      id: 'phi3.5_mini',
      name: 'Phi-3.5 Mini (3.8B)',
      description: "Microsoft's powerful lightweight reasoning model, outstanding in math and logic.",
      downloadUrl: "https://huggingface.co/microsoft/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf",
      fileName: "Phi-3.5-mini-instruct-Q4_K_M.gguf",
      size: "2.8 GB",
      ramRequired: "4.5 GB RAM",
      quantization: "GGUF",
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

  Future<void> downloadModel(
    AIModel model,
    Function(double progress) onProgress, {
    bool resume = false,
  }) async {
    if (kIsWeb) {
      _cancelToken = CancelToken();
      double startP = resume ? model.downloadProgress : 0.0;
      for (double p = startP; p <= 1.0; p += 0.05) {
        if (_cancelToken?.isCancelled == true) {
          final errorObj = _cancelToken?.cancelError;
          String reason = 'Cancelled by user';
          if (errorObj is DioException) {
            reason = errorObj.error?.toString() ?? errorObj.message ?? 'Cancelled by user';
          } else if (errorObj != null) {
            reason = errorObj.toString();
          }
          throw DioException(
            requestOptions: RequestOptions(path: model.downloadUrl),
            message: reason,
            error: reason,
            type: DioExceptionType.cancel,
          );
        }
        await Future.delayed(const Duration(milliseconds: 80));
        onProgress(p);
      }
      await _saveInstalledStatus(model.id, true);
      return;
    }

    _cancelToken = CancelToken();
    final dirPath = await _modelsDir;
    final filePath = '$dirPath/${model.fileName}';
    final file = File(filePath);

    if (!resume && await file.exists()) {
      await file.delete();
    }

    int startBytes = 0;
    if (resume && await file.exists()) {
      startBytes = await file.length();
    }

    RandomAccessFile? fileAccess;
    try {
      final response = await _dio.get<ResponseBody>(
        model.downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: startBytes > 0 ? {'range': 'bytes=$startBytes-'} : null,
        ),
        cancelToken: _cancelToken,
      );

      final int statusCode = response.statusCode ?? 200;
      final bool isRange = statusCode == 206;

      if (!isRange) {
        startBytes = 0;
        if (await file.exists()) {
          await file.delete();
        }
      }

      fileAccess = await file.open(mode: isRange ? FileMode.append : FileMode.write);

      final totalBytesInResponse = int.tryParse(response.headers.value('content-length') ?? '') ?? -1;
      final totalBytes = (totalBytesInResponse != -1) ? (totalBytesInResponse + startBytes) : -1;

      int receivedBytes = startBytes;
      await for (final chunk in response.data!.stream) {
        if (_cancelToken?.isCancelled == true) {
          break;
        }
        await fileAccess.writeFrom(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != -1) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      if (_cancelToken?.isCancelled == true) {
        throw DioException(
          requestOptions: RequestOptions(path: model.downloadUrl),
          message: _cancelToken?.cancelError?.message ?? 'Cancelled by user',
          type: DioExceptionType.cancel,
        );
      }

      await fileAccess.close();
      fileAccess = null;

      // Validate GGUF file header and integrity
      if (!kIsWeb) {
        final validation = await GgufValidator.validateFile(filePath);
        if (!validation.isValid) {
          debugPrint("[LocalMind] GGUF validation failed for ${model.name}: ${validation.error}");
          if (await file.exists()) {
            await file.delete();
          }
          await _saveInstalledStatus(model.id, false);
          throw Exception("Downloaded file is corrupt or invalid GGUF format: ${validation.error}");
        }
      }

      await _saveInstalledStatus(model.id, true);
    } catch (e) {
      if (fileAccess != null) {
        try {
          await fileAccess.close();
        } catch (_) {}
      }

      if (e is DioException && CancelToken.isCancel(e)) {
        final reason = e.error?.toString() ?? e.message ?? '';
        if (reason == 'pause') {
          rethrow;
        }
      }

      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  void cancelDownload({String? reason}) {
    _cancelToken?.cancel(reason ?? 'Cancelled by user');
  }

  Future<void> deleteModel(String modelId) async {
    final model = availableModels.firstWhere((m) => m.id == modelId);
    if (!kIsWeb) {
      final dirPath = await _modelsDir;
      final filePath = '$dirPath/${model.fileName}';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
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
      debugPrint("[LocalMind] Installed model verification failed for $modelId: ${validation.error}. Cleaning up corrupt file.");
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
