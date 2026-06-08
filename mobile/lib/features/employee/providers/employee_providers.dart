import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

final todayAttendanceProvider = FutureProvider<AttendanceModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }

  try {
    return await ref
        .watch(attendanceRepositoryProvider)
        .getTodayAttendanceFromApi(userId: user.id);
  } on ApiException catch (error) {
    await expireSessionOnUnauthorized(ref, error);
    rethrow;
  }
});
