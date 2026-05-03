import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_repository.dart';
import 'attendance_repository.dart';
import 'auth_repository.dart';
import '../dummy/dummy_attendances.dart';
import '../models/attendance_model.dart';
import 'office_repository.dart';
import 'user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return const UserRepository();
});

class AttendanceStoreController extends Notifier<List<AttendanceModel>> {
  @override
  List<AttendanceModel> build() => List<AttendanceModel>.of(dummyAttendances);

  Future<AttendanceModel> clockIn({
    required String userId,
    required String officeId,
    required DateTime attendanceDate,
    required DateTime clockInTime,
    required double clockInLat,
    required double clockInLng,
    required bool isOutside,
    required String? outsideReason,
    required String clockInPhotoId,
  }) async {
    final repository = AttendanceRepository(state);
    final submitted = await repository.clockIn(
      userId: userId,
      officeId: officeId,
      attendanceDate: attendanceDate,
      clockInTime: clockInTime,
      clockInLat: clockInLat,
      clockInLng: clockInLng,
      isOutside: isOutside,
      outsideReason: outsideReason,
      clockInPhotoId: clockInPhotoId,
    );

    state = [
      for (final attendance in state)
        if (_matchesUserAndDate(submitted, attendance))
          submitted
        else
          attendance,
      if (!state.any(
        (attendance) => _matchesUserAndDate(submitted, attendance),
      ))
        submitted,
    ];

    return submitted;
  }

  Future<AttendanceModel> clockOut({
    required String attendanceId,
    required DateTime clockOutTime,
  }) async {
    final repository = AttendanceRepository(state);
    final submitted = await repository.clockOut(
      attendanceId: attendanceId,
      clockOutTime: clockOutTime,
    );

    state = [
      for (final attendance in state)
        if (attendance.id == submitted.id) submitted else attendance,
    ];

    return submitted;
  }

  bool _matchesUserAndDate(AttendanceModel submitted, AttendanceModel current) {
    return submitted.userId == current.userId &&
        AttendanceRepository.isSameDate(
          submitted.attendanceDate,
          current.attendanceDate,
        );
  }
}

final attendanceStoreProvider =
    NotifierProvider<AttendanceStoreController, List<AttendanceModel>>(
      AttendanceStoreController.new,
    );

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(attendanceStoreProvider));
});

final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  return const OfficeRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(userRepositoryProvider));
});
