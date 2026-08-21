import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_llm_handler.dart';
import 'local_llm_helper.dart';
import 'prompt_builder.dart';
import 'model_chat_template_service.dart';
import 'settings_service.dart';

class LLMService {
  String? _loadedModelPath;
  String _activeModelName = "Offline AI";
  String _activeChatTemplate = "chatml";
  InferenceSettings _settings = InferenceSettings();

  void updateSettings(InferenceSettings settings) {
    _settings = settings;
  }

  Future<void> loadModel(
    String modelPath, {
    String? modelName,
    String? chatTemplate,
    InferenceSettings? settings,
  }) async {
    if (modelPath.isEmpty) {
      throw Exception("Model path is empty.");
    }
    if (settings != null) {
      _settings = settings;
    }

    _loadedModelPath = modelPath;
    if (modelName != null) {
      _activeModelName = modelName;
    } else {
      _activeModelName = _getModelFriendlyName();
    }

    _activeChatTemplate = ModelChatTemplateService.resolveTemplate(
      chatTemplate ?? '',
      modelId: modelName,
      fileName: modelPath,
    );

    debugPrint("[LLM] Loading model at: $modelPath (template=$_activeChatTemplate)");
    try {
      await LocalLLMHandler.loadModel(modelPath, settings: _settings);
      debugPrint("[LLM] MODEL_LOADED=true path=$modelPath");
    } catch (e) {
      debugPrint("[LLM] [ERROR] Failed to load model: $e");
      _loadedModelPath = null;
      rethrow;
    }
  }

  /// Pure offline streaming token generation with model-aware prompt formatting and multi-chunk stop token cleaning.
  Stream<String> generateStream(
    String userMessage, {
    String? chatTemplate,
    List<ChatMessageItem>? history,
    InferenceSettings? settings,
  }) async* {
    if (_loadedModelPath == null) {
      throw Exception("No model is currently loaded. Please select and install a model first.");
    }

    final activeSettings = settings ?? _settings;
    final modelName = _activeModelName;
    final template = ModelChatTemplateService.resolveTemplate(
      chatTemplate ?? _activeChatTemplate,
      modelId: modelName,
      fileName: _loadedModelPath,
    );

    final formattedPrompt = PromptBuilder.buildPrompt(
      userMessage: userMessage,
      chatTemplate: template,
      history: history,
      maxContextChars: activeSettings.contextLength * 3,
    );

    debugPrint("[LLM] ACTIVE_MODEL=$modelName");
    debugPrint("[LLM] CHAT_TEMPLATE=$template");
    debugPrint("[LLM] PROMPT_CREATED length=${formattedPrompt.length}");

    final stopTokens = PromptBuilder.getStopTokensForTemplate(template);
    final cleaner = StreamStopTokenCleaner(stopTokens);

    await for (final rawChunk in LocalLLMHandler.generateStream(
      formattedPrompt,
      modelName,
      _loadedModelPath!,
      settings: activeSettings,
    )) {
      final cleanedChunk = cleaner.processChunk(rawChunk);
      if (cleanedChunk.isNotEmpty) {
        yield cleanedChunk;
      }
    }

    final trailing = cleaner.flush();
    if (trailing.isNotEmpty) {
      yield trailing;
    }
  }

  /// Pure offline single-response generation with model-aware prompt formatting.
  Future<String> generateResponse(
    String userMessage, {
    String? chatTemplate,
    List<ChatMessageItem>? history,
    InferenceSettings? settings,
  }) async {
    if (_loadedModelPath == null) {
      throw Exception("No model is currently loaded. Please select and install a model first.");
    }

    final activeSettings = settings ?? _settings;
    final modelName = _activeModelName;
    final template = ModelChatTemplateService.resolveTemplate(
      chatTemplate ?? _activeChatTemplate,
      modelId: modelName,
      fileName: _loadedModelPath,
    );

    final formattedPrompt = PromptBuilder.buildPrompt(
      userMessage: userMessage,
      chatTemplate: template,
      history: history,
      maxContextChars: activeSettings.contextLength * 3,
    );

    final rawResponse = await LocalLLMHandler.generateResponse(
      formattedPrompt,
      modelName,
      _loadedModelPath!,
      settings: activeSettings,
    );
    return PromptBuilder.cleanStopTokens(rawResponse, templateName: template);
  }

  void stopGeneration() {
    LocalLLMHandler.stopGeneration();
  }

  Future<void> unloadModel() async {
    _loadedModelPath = null;
    await LocalLLMHandler.unloadModel();
    debugPrint("[LLM] MODEL_UNLOADED=true in LLMService.");
  }

  bool get isModelLoaded => _loadedModelPath != null && LocalLLMHandler.isModelLoaded;
  String? get loadedModelPath => _loadedModelPath;
  String get activeModelName => _activeModelName;
  String get activeChatTemplate => _activeChatTemplate;
  InferenceSettings get currentSettings => _settings;

  LLMDiagnostics getDiagnostics() {
    return LocalLLMHandler.getDiagnostics();
  }

  String _getModelFriendlyName() {
    if (_loadedModelPath == null) return "Local AI";
    final pathLower = _loadedModelPath!.toLowerCase();
    if (pathLower.contains("gemma-3") || pathLower.contains("gemma3")) return "Gemma 3 1B";
    if (pathLower.contains("qwen2.5-1.5b")) return "Qwen 2.5 1.5B";
    if (pathLower.contains("qwen2.5-3b")) return "Qwen 2.5 3B";
    if (pathLower.contains("llama-3.2") || pathLower.contains("llama3")) return "Llama 3.2 1B";
    if (pathLower.contains("smollm2")) return "SmolLM2 1.7B";
    if (pathLower.contains("phi-3.5") || pathLower.contains("phi3")) return "Phi-3.5 Mini (3.8B)";
    return "Offline Model";
  }
}
