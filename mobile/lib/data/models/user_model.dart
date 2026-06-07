import 'package:equatable/equatable.dart';

import '../../core/enums/user_role.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.jabatan,
    this.photoId,
    this.photoUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _userRoleFromApi(json['role']?.toString()),
      isActive: _isActiveFromApi(json['status']?.toString()),
      jabatan: json['jabatan']?.toString(),
      photoId: json['photoId']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      createdAt: _dateTimeFromApi(json['createdAt']?.toString()),
    );
  }

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? jabatan;
  final String? photoId;
  final String? photoUrl;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    isActive,
    jabatan,
    photoId,
    photoUrl,
    createdAt,
  ];
}

UserRole _userRoleFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'ADMIN' => UserRole.admin,
    _ => UserRole.employee,
  };
}

bool _isActiveFromApi(String? value) {
  return value?.toUpperCase() != 'INACTIVE';
}

DateTime? _dateTimeFromApi(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
