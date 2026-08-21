import 'package:shared_preferences/shared_preferences.dart';

class InferenceSettings {
  final double temperature;
  final double topP;
  final int topK;
  final double repeatPenalty;
  final int contextLength;
  final int cpuThreads;
  final int maxTokens;
  final bool isSafeModeEnabled;
  final bool isAutoOffloadEnabled;

  InferenceSettings({
    this.temperature = 0.70,
    this.topP = 0.90,
    this.topK = 40,
    this.repeatPenalty = 1.10,
    this.contextLength = 2048,
    this.cpuThreads = 0, // 0 = auto
    this.maxTokens = 1024,
    this.isSafeModeEnabled = false,
    this.isAutoOffloadEnabled = true,
  });

  InferenceSettings copyWith({
    double? temperature,
    double? topP,
    int? topK,
    double? repeatPenalty,
    int? contextLength,
    int? cpuThreads,
    int? maxTokens,
    bool? isSafeModeEnabled,
    bool? isAutoOffloadEnabled,
  }) {
    return InferenceSettings(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      repeatPenalty: repeatPenalty ?? this.repeatPenalty,
      contextLength: contextLength ?? this.contextLength,
      cpuThreads: cpuThreads ?? this.cpuThreads,
      maxTokens: maxTokens ?? this.maxTokens,
      isSafeModeEnabled: isSafeModeEnabled ?? this.isSafeModeEnabled,
      isAutoOffloadEnabled: isAutoOffloadEnabled ?? this.isAutoOffloadEnabled,
    );
  }
}

class SettingsService {
  static const String _selectedModelKey = 'selected_model_id';
  static const String _chatHistoryKey = 'chat_history_enabled';

  static const String _temperatureKey = 'inf_temperature';
  static const String _topPKey = 'inf_top_p';
  static const String _topKKey = 'inf_top_k';
  static const String _repeatPenaltyKey = 'inf_repeat_penalty';
  static const String _contextLengthKey = 'inf_context_length';
  static const String _cpuThreadsKey = 'inf_cpu_threads';
  static const String _maxTokensKey = 'inf_max_tokens';
  static const String _safeModeKey = 'inf_safe_mode';
  static const String _autoOffloadKey = 'inf_auto_offload';

  Future<void> setSelectedModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, modelId);
  }

  Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModelKey);
  }

  Future<void> setChatHistoryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chatHistoryKey, enabled);
  }

  Future<bool> getChatHistoryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chatHistoryKey) ?? true;
  }

  Future<InferenceSettings> getInferenceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return InferenceSettings(
      temperature: prefs.getDouble(_temperatureKey) ?? 0.70,
      topP: prefs.getDouble(_topPKey) ?? 0.90,
      topK: prefs.getInt(_topKKey) ?? 40,
      repeatPenalty: prefs.getDouble(_repeatPenaltyKey) ?? 1.10,
      contextLength: prefs.getInt(_contextLengthKey) ?? 2048,
      cpuThreads: prefs.getInt(_cpuThreadsKey) ?? 0,
      maxTokens: prefs.getInt(_maxTokensKey) ?? 1024,
      isSafeModeEnabled: prefs.getBool(_safeModeKey) ?? false,
      isAutoOffloadEnabled: prefs.getBool(_autoOffloadKey) ?? true,
    );
  }

  Future<void> saveInferenceSettings(InferenceSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_temperatureKey, settings.temperature);
    await prefs.setDouble(_topPKey, settings.topP);
    await prefs.setInt(_topKKey, settings.topK);
    await prefs.setDouble(_repeatPenaltyKey, settings.repeatPenalty);
    await prefs.setInt(_contextLengthKey, settings.contextLength);
    await prefs.setInt(_cpuThreadsKey, settings.cpuThreads);
    await prefs.setInt(_maxTokensKey, settings.maxTokens);
    await prefs.setBool(_safeModeKey, settings.isSafeModeEnabled);
    await prefs.setBool(_autoOffloadKey, settings.isAutoOffloadEnabled);
  }

  Future<void> resetInferenceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_temperatureKey);
    await prefs.remove(_topPKey);
    await prefs.remove(_topKKey);
    await prefs.remove(_repeatPenaltyKey);
    await prefs.remove(_contextLengthKey);
    await prefs.remove(_cpuThreadsKey);
    await prefs.remove(_maxTokensKey);
    await prefs.remove(_safeModeKey);
    await prefs.remove(_autoOffloadKey);
  }
}
