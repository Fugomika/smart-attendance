import '../dummy/dummy_users.dart';
import '../models/user_model.dart';

class AuthRepository {
  const AuthRepository();

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    if (password != 'password') {
      return null;
    }

    for (final user in dummyUsers) {
      if (user.email == email && user.isActive) {
        return user;
      }
    }

    return null;
  }
}
