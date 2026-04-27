import 'package:equatable/equatable.dart';

import '../../core/enums/user_role.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.photoId,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? photoId;

  @override
  List<Object?> get props => [id, name, email, role, isActive, photoId];
}
