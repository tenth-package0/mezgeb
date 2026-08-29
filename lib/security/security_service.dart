import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  SecurityService({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final _pinKdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 180000,
    bits: 256,
  );

  Future<bool> hasPin() async => await _storage.read(key: _pinHashKey) != null;

  Future<void> createPin(String pin) async {
    final salt = _randomBytes(32);
    final hash = await _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: base64Encode(salt));
    await _storage.write(key: _pinHashKey, value: base64Encode(hash));
    await _storage.write(key: _biometricKey, value: 'true');
  }

  Future<bool> verifyPin(String pin) async {
    final saltValue = await _storage.read(key: _pinSaltKey);
    final hashValue = await _storage.read(key: _pinHashKey);
    if (saltValue == null || hashValue == null) return false;
    final actual = await _hashPin(pin, base64Decode(saltValue));
    final expected = base64Decode(hashValue);
    return _constantTimeEquals(actual, expected);
  }

  Future<bool> changePin(String currentPin, String nextPin) async {
    if (!await verifyPin(currentPin)) return false;
    await createPin(nextPin);
    return true;
  }

  Future<bool> biometricEnabled() async {
    return (await _storage.read(key: _biometricKey)) != 'false';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await biometricEnabled()) return false;
    if (!await _localAuth.isDeviceSupported()) return false;
    return _localAuth.authenticate(
      localizedReason: 'Unlock Mezgeb',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }

  Future<List<int>> databasePassphrase() async {
    final existing = await _storage.read(key: _databaseKey);
    if (existing != null) return base64Decode(existing);
    final passphrase = _randomBytes(64);
    await _storage.write(key: _databaseKey, value: base64Encode(passphrase));
    return passphrase;
  }

  Future<SecretKey> fileSecretKey() async {
    final existing = await _storage.read(key: _fileKey);
    if (existing != null) return SecretKey(base64Decode(existing));
    final key = _randomBytes(32);
    await _storage.write(key: _fileKey, value: base64Encode(key));
    return SecretKey(key);
  }

  Future<List<int>> _hashPin(String pin, List<int> salt) async {
    final key = await _pinKdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static const _pinSaltKey = 'pin_salt';
  static const _pinHashKey = 'pin_hash';
  static const _biometricKey = 'biometric_enabled';
  static const _databaseKey = 'database_passphrase';
  static const _fileKey = 'file_encryption_key';
}
