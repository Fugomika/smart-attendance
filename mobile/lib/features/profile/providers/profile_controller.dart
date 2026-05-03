import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.photoPath,
  });

  final String userId;
  final String name;
  final String email;
  final UserRole role;
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
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return ProfileState(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
    );
  }

  @override
  List<Object?> get props => [userId, name, email, role, photoPath];
}

class ProfileController extends Notifier<ProfileState?> {
  @override
  ProfileState? build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return null;
    }

    return ProfileState(
      userId: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      photoPath: user.photoId,
    );
  }

  void saveProfile({
    required String name,
    required String email,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    final current = state;
    if (current == null) {
      return;
    }

    state = current.copyWith(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      photoPath: photoPath,
      clearPhoto: clearPhoto,
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState?>(ProfileController.new);
