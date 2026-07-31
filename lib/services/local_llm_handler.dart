import 'local_llm_stub.dart'
    if (dart.library.html) 'local_llm_web.dart'
    if (dart.library.io) 'local_llm_io.dart';

class LocalLLMHandler {
  static final _llm = getPlatformLLM();

  static Future<void> loadModel(String modelPath) => _llm.loadModel(modelPath);
  static Future<String> generateResponse(String prompt, String modelName, String modelPath) =>
      _llm.generateResponse(prompt, modelName, modelPath);
  static Future<void> unloadModel() => _llm.unloadModel();
  static bool get isModelLoaded => _llm.isModelLoaded;
}
