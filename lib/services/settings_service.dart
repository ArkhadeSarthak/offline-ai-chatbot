import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _selectedModelKey = 'selected_model_id';
  static const String _chatHistoryKey = 'chat_history_enabled';

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
}
