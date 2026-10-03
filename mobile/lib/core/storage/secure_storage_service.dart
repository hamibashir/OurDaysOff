import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  /// Save the Laravel Sanctum bearer token
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Retrieve the Laravel Sanctum bearer token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Clear the authentication token on logout or 401
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  /// Save cached user JSON payload
  Future<void> saveUserData(String jsonString) async {
    await _storage.write(key: _userDataKey, value: jsonString);
  }

  /// Retrieve cached user JSON payload
  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  /// Wipe all secured keys
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
