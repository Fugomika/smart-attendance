import '../../core/enums/user_role.dart';
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

  Future<UserModel?> register({
    required String name,
    required String email,
    required String position,
    required String password,
    String? photoPath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final normalizedEmail = email.trim().toLowerCase();
    final emailTaken = dummyUsers.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );
    if (emailTaken) {
      return null;
    }

    return UserModel(
      id: 'employee-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      role: UserRole.employee,
      isActive: true,
      photoId: photoPath,
    );
  }

  Future<void> requestPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Dummy: tidak peduli email terdaftar atau tidak. Selalu sukses generik
    // untuk menghindari user enumeration. Diganti API saat backend siap.
  }
}
