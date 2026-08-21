import 'dart:async';
import 'local_llm_helper.dart';
import 'settings_service.dart';

LocalLLM getPlatformLLM() => LocalLLMWeb();

class LocalLLMWeb implements LocalLLM {
  bool _loaded = false;
  bool _isCancelled = false;

  @override
  Future<void> loadModel(String modelPath, {InferenceSettings? settings}) async {
    _loaded = true;
  }

  @override
  Future<String> generateResponse(String prompt, String modelName, String modelPath, {InferenceSettings? settings}) async {
    final buffer = StringBuffer();
    await for (final token in generateStream(prompt, modelName, modelPath, settings: settings)) {
      buffer.write(token);
    }
    return buffer.toString().trim();
  }

  @override
  Stream<String> generateStream(String prompt, String modelName, String modelPath, {InferenceSettings? settings}) async* {
    _isCancelled = false;
    final promptLower = prompt.toLowerCase();
    String fullResponse = "I received your offline prompt: \"$prompt\". As $modelName, I am running completely locally.";
    
    if (promptLower.contains("hello") || promptLower.contains("hi")) {
      fullResponse = "Hello! I am $modelName, running locally on your device. How can I assist you offline today?";
    } else if (promptLower.contains("flutter")) {
      fullResponse = "Flutter is an open-source UI software development kit created by Google for building natively compiled applications.";
    }

    final words = fullResponse.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (_isCancelled) break;
      await Future.delayed(const Duration(milliseconds: 30));
      yield words[i] + (i < words.length - 1 ? ' ' : '');
    }
  }

  @override
  void stopGeneration() {
    _isCancelled = true;
  }

  @override
  Future<void> unloadModel() async {
    _loaded = false;
  }

  @override
  bool get isModelLoaded => _loaded;

  @override
  LLMDiagnostics getDiagnostics() {
    return LLMDiagnostics(
      activeModelPath: "web_demo",
      isLoaded: _loaded,
      activeContextSize: 2048,
      activeThreadCount: 1,
      lastInferenceDurationMs: 300,
      lastTokenCount: 10,
      tokensPerSecond: 33.3,
      lastFirstTokenLatency: "30ms",
      lastError: null,
      lastCrashMarker: "IDLE",
    );
  }
}
