import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

final todayAttendanceProvider = Provider<AttendanceModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }

  return ref.watch(attendanceRepositoryProvider).getTodayAttendance(user.id);
});
