import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/auth_token_store.dart';
import '../../core/utils/file_name_from_path.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  const AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  Future<UserModel?> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final response = await _apiClient.post<AuthSessionModel>(
      '/auth/mobile/login',
      data: {'email': email.trim(), 'password': password},
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AuthSessionModel.fromJson(json);
        }

        throw const FormatException('Invalid login response.');
      },
    );

    final session = response.data;
    if (session.accessToken.trim().isEmpty) {
      throw const FormatException('Login response missing access token.');
    }

    await _tokenStore.saveToken(session.accessToken, persist: remember);
    return session.user;
  }

  Future<UserModel> me() async {
    final response = await _apiClient.get<UserModel>(
      '/auth/me',
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return UserModel.fromJson(json);
        }

        throw const FormatException('Invalid current user response.');
      },
    );

    return response.data;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<Object?>('/auth/logout', parseData: (_) => null);
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String position,
    required String password,
    String? photoPath,
  }) async {
    final normalizedPhotoPath = photoPath?.trim();
    final response = await _apiClient.postMultipart<UserModel>(
      '/auth/register',
      data: FormData.fromMap({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'jabatan': position.trim(),
        if (normalizedPhotoPath != null && normalizedPhotoPath.isNotEmpty)
          'avatar': await MultipartFile.fromFile(
            normalizedPhotoPath,
            filename: fileNameFromPath(
              normalizedPhotoPath,
              fallback: 'avatar.jpg',
            ),
          ),
      }),
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return UserModel.fromJson(json);
        }

        throw const FormatException('Invalid register response.');
      },
    );

    return response.data;
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _apiClient.post<Object?>(
      '/auth/forgot-password',
      data: {'email': email.trim().toLowerCase()},
      parseData: (_) => null,
    );
  }
}
