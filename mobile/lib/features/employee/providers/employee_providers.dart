import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/attendance_model.dart';
import '../../../data/models/office_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

final todayAttendanceProvider = Provider<AttendanceModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }

  return ref.watch(attendanceRepositoryProvider).getTodayAttendance(user.id);
});

final todayAttendanceOfficeProvider = Provider<OfficeModel?>((ref) {
  final attendance = ref.watch(todayAttendanceProvider);
  if (attendance == null) {
    return null;
  }

  return ref.watch(officeRepositoryProvider).getOfficeById(attendance.officeId);
});
