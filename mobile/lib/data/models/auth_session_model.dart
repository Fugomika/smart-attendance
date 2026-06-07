import 'user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response user.');
    }

    return AuthSessionModel(
      accessToken: json['accessToken']?.toString() ?? '',
      expiresIn: int.tryParse(json['expiresIn']?.toString() ?? '') ?? 0,
      user: UserModel.fromJson(userJson),
    );
  }

  final String accessToken;
  final int expiresIn;
  final UserModel user;
}
