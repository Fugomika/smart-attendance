import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class ProfileRepository {
  const ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String jabatan,
    String? photoId,
    bool clearPhoto = false,
  }) async {
    final data = <String, Object?>{
      'name': name.trim(),
      'jabatan': jabatan.trim(),
    };

    if (clearPhoto) {
      data['photoId'] = null;
    } else if (photoId != null && photoId.trim().isNotEmpty) {
      data['photoId'] = photoId.trim();
    }

    final response = await _apiClient.patch<UserModel>(
      '/users/$userId',
      data: data,
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return UserModel.fromJson(json);
        }

        throw const FormatException('Invalid profile update response.');
      },
    );

    return response.data;
  }

  Future<void> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch<Object?>(
      '/users/$userId/password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      parseData: (_) => null,
    );
  }
}
