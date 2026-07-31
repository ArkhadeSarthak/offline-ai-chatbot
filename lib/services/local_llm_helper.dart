abstract class LocalLLM {
  Future<void> loadModel(String modelPath);
  Future<String> generateResponse(String prompt, String modelName, String modelPath);
  Future<void> unloadModel();
  bool get isModelLoaded;
}
