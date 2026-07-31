import 'local_llm_helper.dart';

LocalLLM getPlatformLLM() => LocalLLMWeb();

class LocalLLMWeb implements LocalLLM {
  bool _loaded = false;

  @override
  Future<void> loadModel(String modelPath) async {
    _loaded = true;
  }

  @override
  Future<String> generateResponse(String prompt, String modelName, String modelPath) async {
    await Future.delayed(const Duration(seconds: 2));
    final promptLower = prompt.toLowerCase();
    if (promptLower.contains("hello") || promptLower.contains("hi")) {
      return "Hello! I am $modelName, running locally on your device. How can I assist you offline today?";
    } else if (promptLower.contains("name")) {
      return "I am $modelName, an offline-optimized AI model currently loaded from device storage at `$modelPath`.";
    } else if (promptLower.contains("weather")) {
      return "I cannot check live weather reports because I am currently operating offline. Please check your internet connection.";
    } else if (promptLower.contains("code") || promptLower.contains("program") || promptLower.contains("write a")) {
      return "Here is a quick code template for you:\n\n```javascript\n// Offline code assistance template\nfunction greet(name) {\n  return `Hello, \${name}!`;\n}\nconsole.log(greet('World'));\n```\n\nTo compile complex code offline, you can run native execution targets on device hardware.";
    } else {
      return "I received your offline prompt: \"$prompt\". As $modelName, I am running completely locally off your device storage.";
    }
  }

  @override
  Future<void> unloadModel() async {
    _loaded = false;
  }

  @override
  bool get isModelLoaded => _loaded;
}
