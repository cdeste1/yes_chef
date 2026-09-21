import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen TTS voice (by name + locale, the same shape
/// flutter_tts's getVoices/setVoice use) so Cook Mode narration keeps
/// sounding the same across recipes/sessions instead of resetting to the
/// platform default every time.
class VoiceSettingsService {
  VoiceSettingsService._();

  static const String _nameKey = 'tts_voice_name';
  static const String _localeKey = 'tts_voice_locale';

  static Future<Map<String, String>?> getSavedVoice() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    final locale = prefs.getString(_localeKey);
    if (name == null || locale == null) return null;
    return {'name': name, 'locale': locale};
  }

  static Future<void> saveVoice(String name, String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_localeKey, locale);
  }

  static Future<void> clearVoice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_localeKey);
  }
}
