// lib/core/secure_storage.dart
//
// Wrapper around flutter_secure_storage.
// On Android, flutter_secure_storage v11+ uses AES-GCM encryption backed by
// the Android Keystore by default — no extra options needed.
// The token is encrypted at rest and tied to the device.
// We NEVER use plain SharedPreferences for the JWT.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class SecureStorage {
  // Android-specific options.
  // In v11+, the default AndroidOptions already use Android Keystore
  // (AES-GCM / RSA OAEP key wrapping) — stronger than EncryptedSharedPreferences.
  static const _androidOptions = AndroidOptions(
    resetOnError: true, // Clear corrupted data on error rather than crashing.
  );

  // A single shared instance; the constructor is cheap.
  static const _storage = FlutterSecureStorage(aOptions: _androidOptions);

  /// Save the JWT. Overwrites any previously stored value.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Read the JWT. Returns null if no token has been saved yet.
  static Future<String?> readToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }

  /// Delete the JWT (called on logout or session expiry).
  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }
}
