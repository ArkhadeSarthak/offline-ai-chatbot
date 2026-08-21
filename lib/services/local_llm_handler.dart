import 'local_llm_stub.dart'
    if (dart.library.html) 'local_llm_web.dart'
    if (dart.library.io) 'local_llm_io.dart';
import 'local_llm_helper.dart';
import 'settings_service.dart';

class LocalLLMHandler {
  static final _llm = getPlatformLLM();

  static Future<void> loadModel(String modelPath, {InferenceSettings? settings}) =>
      _llm.loadModel(modelPath, settings: settings);

  static Future<String> generateResponse(
          String prompt, String modelName, String modelPath,
          {InferenceSettings? settings}) =>
      _llm.generateResponse(prompt, modelName, modelPath, settings: settings);

  static Stream<String> generateStream(
          String prompt, String modelName, String modelPath,
          {InferenceSettings? settings}) =>
      _llm.generateStream(prompt, modelName, modelPath, settings: settings);

  static void stopGeneration() => _llm.stopGeneration();

  static Future<void> unloadModel() => _llm.unloadModel();

  static bool get isModelLoaded => _llm.isModelLoaded;

  static LLMDiagnostics getDiagnostics() => _llm.getDiagnostics();
}
