import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_repository.dart';
import 'attendance_repository.dart';
import 'auth_repository.dart';
import 'user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return const UserRepository();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return const AttendanceRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(userRepositoryProvider));
});
