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
    return _readBool(_deleteOriginalsKey);
  }

  Future<void> setDeleteOriginals(bool value) async {
    await _writeBool(_deleteOriginalsKey, value);
  }

  Future<bool> warmNight() async {
    return _readBool(_warmNightKey);
  }

  Future<void> setWarmNight(bool value) async {
    await _writeBool(_warmNightKey, value);
  }

  Future<bool> introSeen() async {
    return _readBool(_introSeenKey);
  }

  Future<void> setIntroSeen(bool value) async {
    await _writeBool(_introSeenKey, value);
  }

  Future<bool> _readBool(String key) async {
    return (await _storage.read(key: key)) == 'true';
  }

  Future<void> _writeBool(String key, bool value) {
    return _storage.write(key: key, value: value.toString());
  }

  static const _themeKey = 'theme_id';
  static const _deleteOriginalsKey = 'delete_originals';
  static const _warmNightKey = 'warm_night';
  static const _introSeenKey = 'intro_seen';
}
