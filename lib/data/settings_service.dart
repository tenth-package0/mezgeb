import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  SettingsService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String> themeId() async =>
      await _storage.read(key: _themeKey) ?? 'one';

  Future<void> setThemeId(String value) async {
    await _storage.write(key: _themeKey, value: value);
  }

  Future<bool> deleteOriginals() async {
    return (await _storage.read(key: _deleteOriginalsKey)) == 'true';
  }

  Future<void> setDeleteOriginals(bool value) async {
    await _storage.write(key: _deleteOriginalsKey, value: value.toString());
  }

  Future<bool> warmNight() async {
    return (await _storage.read(key: _warmNightKey)) == 'true';
  }

  Future<void> setWarmNight(bool value) async {
    await _storage.write(key: _warmNightKey, value: value.toString());
  }

  Future<bool> introSeen() async {
    return (await _storage.read(key: _introSeenKey)) == 'true';
  }

  Future<void> setIntroSeen(bool value) async {
    await _storage.write(key: _introSeenKey, value: value.toString());
  }

  static const _themeKey = 'theme_id';
  static const _deleteOriginalsKey = 'delete_originals';
  static const _warmNightKey = 'warm_night';
  static const _introSeenKey = 'intro_seen';
}
