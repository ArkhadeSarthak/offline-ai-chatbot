import 'settings_service.dart';

class LLMDiagnostics {
  final String? activeModelPath;
  final bool isLoaded;
  final int activeContextSize;
  final int activeThreadCount;
  final int lastInferenceDurationMs;
  final int lastTokenCount;
  final double tokensPerSecond;
  final String lastFirstTokenLatency;
  final String? lastError;
  final String lastCrashMarker;

  LLMDiagnostics({
    this.activeModelPath,
    required this.isLoaded,
    required this.activeContextSize,
    required this.activeThreadCount,
    required this.lastInferenceDurationMs,
    required this.lastTokenCount,
    required this.tokensPerSecond,
    required this.lastFirstTokenLatency,
    this.lastError,
    this.lastCrashMarker = 'IDLE',
  });
}

abstract class LocalLLM {
  Future<void> loadModel(String modelPath, {InferenceSettings? settings});
  Future<String> generateResponse(String prompt, String modelName, String modelPath, {InferenceSettings? settings});
  Stream<String> generateStream(String prompt, String modelName, String modelPath, {InferenceSettings? settings});
  void stopGeneration();
  Future<void> unloadModel();
  bool get isModelLoaded;
  LLMDiagnostics getDiagnostics();
}
