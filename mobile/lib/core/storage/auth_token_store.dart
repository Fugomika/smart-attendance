import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'smart_attendance_access_token';

  final FlutterSecureStorage _secureStorage;
  String? _memoryToken;

  Future<String?> readToken() async {
    if (_memoryToken != null && _memoryToken!.trim().isNotEmpty) {
      return _memoryToken;
    }

    return _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token, {required bool persist}) async {
    final normalizedToken = token.trim();
    _memoryToken = normalizedToken;

    if (persist) {
      await _secureStorage.write(key: _tokenKey, value: normalizedToken);
      return;
    }

    await _secureStorage.delete(key: _tokenKey);
  }

  Future<void> clear() async {
    _memoryToken = null;
    await _secureStorage.delete(key: _tokenKey);
  }
}
