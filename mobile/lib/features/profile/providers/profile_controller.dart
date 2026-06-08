import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.jabatan,
    this.photoPath,
  });

  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? jabatan;
  final String? photoPath;

  String get roleLabel {
    return switch (role) {
      UserRole.admin => 'Admin',
      UserRole.employee => 'Karyawan',
    };
  }

  ProfileState copyWith({
    String? userId,
    String? name,
    String? email,
    UserRole? role,
    String? jabatan,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return ProfileState(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      jabatan: jabatan ?? this.jabatan,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
    );
  }

  @override
  List<Object?> get props => [userId, name, email, role, jabatan, photoPath];
}

class ProfileActionResult {
  const ProfileActionResult._({required this.isSuccess, this.message});

  const ProfileActionResult.success([String? message])
    : this._(isSuccess: true, message: message);

  const ProfileActionResult.failure(String message)
    : this._(isSuccess: false, message: message);

  final bool isSuccess;
  final String? message;
}

class ProfileController extends Notifier<ProfileState?> {
  @override
  ProfileState? build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return null;
    }

    return _stateFromUser(user);
  }

  Future<ProfileActionResult> refreshProfile() async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      ref.read(authControllerProvider.notifier).replaceCurrentUser(user);
      state = _stateFromUser(user);
      return const ProfileActionResult.success();
    } on ApiException catch (error) {
      final message = await _handleProtectedApiError(
        error,
        badRequestMessage: 'Profil gagal dimuat ulang.',
      );
      return ProfileActionResult.failure(message);
    } catch (_) {
      return const ProfileActionResult.failure(
        'Profil gagal dimuat ulang. Silakan coba lagi.',
      );
    }
  }

  Future<ProfileActionResult> saveProfile({
    required String name,
    required String jabatan,
    String? photoPath,
    bool clearPhoto = false,
  }) async {
    final current = state;
    if (current == null) {
      return const ProfileActionResult.failure('Data profil tidak tersedia.');
    }

    try {
      String? uploadedPhotoId;
      if (_isLocalPhotoPath(photoPath)) {
        final uploaded = await ref
            .read(fileRepositoryProvider)
            .uploadProfilePhoto(photoPath!);
        uploadedPhotoId = uploaded.id;
      }

      final updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            userId: current.userId,
            name: name,
            jabatan: jabatan,
            photoId: uploadedPhotoId,
            clearPhoto: clearPhoto,
          );

      ref.read(authControllerProvider.notifier).replaceCurrentUser(updated);
      state = _stateFromUser(updated);
      return const ProfileActionResult.success('Profil berhasil diperbarui.');
    } on ApiException catch (error) {
      final message = await _handleProtectedApiError(
        error,
        badRequestMessage: 'Profil gagal diperbarui.',
      );
      return ProfileActionResult.failure(message);
    } catch (_) {
      return const ProfileActionResult.failure(
        'Profil gagal diperbarui. Silakan coba lagi.',
      );
    }
  }

  Future<ProfileActionResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final current = state;
    if (current == null) {
      return const ProfileActionResult.failure('Data profil tidak tersedia.');
    }

    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            userId: current.userId,
            oldPassword: oldPassword,
            newPassword: newPassword,
          );
      return const ProfileActionResult.success('Password berhasil diperbarui.');
    } on ApiException catch (error) {
      final message = await _handleProtectedApiError(
        error,
        badRequestMessage: 'Password lama tidak sesuai.',
      );
      return ProfileActionResult.failure(message);
    } catch (_) {
      return const ProfileActionResult.failure(
        'Password gagal diperbarui. Silakan coba lagi.',
      );
    }
  }

  ProfileState _stateFromUser(UserModel user) {
    return ProfileState(
      userId: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      jabatan: user.jabatan,
      photoPath: user.photoUrl ?? user.photoId,
    );
  }

  bool _isLocalPhotoPath(String? value) {
    final path = value?.trim();
    if (path == null || path.isEmpty) {
      return false;
    }

    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  Future<String> _handleProtectedApiError(
    ApiException error, {
    required String badRequestMessage,
  }) async {
    if (await expireSessionOnUnauthorized(ref, error)) {
      return 'Sesi berakhir. Silakan login kembali.';
    }

    return switch (error.statusCode) {
      400 => badRequestMessage,
      403 => 'Anda tidak memiliki akses untuk mengubah data ini.',
      404 => 'Data yang diperlukan tidak ditemukan.',
      422 => error.displayMessage,
      _ => error.displayMessage,
    };
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState?>(ProfileController.new);
