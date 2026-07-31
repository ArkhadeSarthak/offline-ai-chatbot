import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'network_helper.dart';
import 'local_llm_handler.dart';

class LLMService {
  String? _loadedModelPath;
  final Dio _dio = Dio();

  Future<void> loadModel(String modelPath) async {
    if (modelPath.isEmpty) {
      throw Exception("Model path is empty.");
    }
    _loadedModelPath = modelPath;
    debugPrint("[LocalMind] Loading model at path: $modelPath");
    try {
      await LocalLLMHandler.loadModel(modelPath);
      debugPrint("[LocalMind] Successfully loaded model at path: $modelPath");
    } catch (e) {
      debugPrint("[LocalMind] [ERROR] Failed to load model at $modelPath: $e");
      _loadedModelPath = null;
      rethrow;
    }
  }

  Future<String> generateResponse(String prompt) async {
    if (_loadedModelPath == null) {
      throw Exception("No model is currently loaded. Load a model first.");
    }

    final modelName = _getModelFriendlyName();
    final hfModelId = _getHuggingFaceModelId();

    // 1. Try Local GGUF Model Response first (primary offline model)
    try {
      final localResponse = await LocalLLMHandler.generateResponse(prompt, modelName, _loadedModelPath!);
      if (localResponse.isNotEmpty && !localResponse.startsWith("Error running model inference")) {
        return localResponse;
      }
      debugPrint("[LocalMind] Local inference returned empty or error response. Attempting online fallback...");
    } catch (e) {
      debugPrint("[LocalMind] Local inference failed: $e. Attempting online fallback...");
    }

    // 2. Online Fallback APIs (if online and local inference failed)
    final isOnline = await NetworkHelper.hasInternetConnection();

    if (isOnline) {
      // A. Try Hugging Face Serverless API (with shorter timeouts to fail fast)
      try {
        final response = await _dio.post(
          "https://api-inference.huggingface.co/models/$hfModelId",
          data: {
            "inputs": prompt,
            "parameters": {
              "max_new_tokens": 300,
              "return_full_text": false,
            }
          },
          options: Options(
            headers: {
              "Content-Type": "application/json",
            },
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is List && data.isNotEmpty) {
            final genText = data[0]['generated_text'];
            if (genText != null && genText.toString().trim().isNotEmpty) {
              return genText.toString().trim();
            }
          } else if (data is Map && data.containsKey('generated_text')) {
            final genText = data['generated_text'];
            if (genText != null && genText.toString().trim().isNotEmpty) {
              return genText.toString().trim();
            }
          }
        }
      } catch (e) {
        debugPrint("[LocalMind] HF Inference API failed for $hfModelId: $e. Trying fallback API...");
      }

      // B. Try Pollinations AI (with shorter timeouts to fail fast)
      try {
        final response = await _dio.post(
          "https://text.pollinations.ai/",
          data: {
            "messages": [
              {
                "role": "system",
                "content": "You are the selected AI model: $modelName. Answer the user's question as this model. Be helpful, concise, and respond in character."
              },
              {"role": "user", "content": prompt}
            ],
            "model": "openai",
            "jsonMode": false,
          },
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final resText = response.data.toString().trim();
          if (resText.isNotEmpty) {
            return resText;
          }
        }
      } catch (e) {
        debugPrint("[LocalMind] Pollinations AI API failed: $e.");
      }
    }

    return "Error: Could not generate response locally or online. Please check your model or internet connection.";
  }

  Future<void> unloadModel() async {
    _loadedModelPath = null;
    await LocalLLMHandler.unloadModel();
    debugPrint("[LocalMind] Model unloaded in LLMService.");
  }

  bool get isModelLoaded => _loadedModelPath != null && LocalLLMHandler.isModelLoaded;

  String _getModelFriendlyName() {
    if (_loadedModelPath == null) return "AI Assistant";
    final pathLower = _loadedModelPath!.toLowerCase();
    if (pathLower.contains("gemma")) return "Gemma 3 1B";
    if (pathLower.contains("qwen2.5-1.5b") || pathLower.contains("qwen3")) return "Qwen3 1.7B";
    if (pathLower.contains("llama")) return "Llama 3.2 1B";
    if (pathLower.contains("smollm")) return "SmolLM2 1.7B";
    if (pathLower.contains("qwen2.5-3b")) return "Qwen 2.5 3B";
    if (pathLower.contains("phi")) return "Phi-3.5 Mini (3.8B)";
    return "Local Offline Model";
  }

  String _getHuggingFaceModelId() {
    if (_loadedModelPath == null) return "Qwen/Qwen2.5-1.5B-Instruct";
    final pathLower = _loadedModelPath!.toLowerCase();
    if (pathLower.contains("gemma")) return "google/gemma-3-1b-it";
    if (pathLower.contains("qwen2.5-1.5b") || pathLower.contains("qwen3")) return "Qwen/Qwen2.5-1.5B-Instruct";
    if (pathLower.contains("llama")) return "meta-llama/Llama-3.2-1B-Instruct";
    if (pathLower.contains("smollm")) return "HuggingFaceTB/SmolLM2-1.7B-Instruct";
    if (pathLower.contains("qwen2.5-3b")) return "Qwen/Qwen2.5-3B-Instruct";
    if (pathLower.contains("phi")) return "microsoft/Phi-3.5-mini-instruct";
    return "Qwen/Qwen2.5-1.5B-Instruct";
  }
}
