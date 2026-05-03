import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_repository.dart';
import 'attendance_repository.dart';
import 'auth_repository.dart';
import '../dummy/dummy_attendances.dart';
import '../dummy/dummy_offices.dart';
import '../models/attendance_model.dart';
import '../models/office_model.dart';
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

class OfficeStoreController extends Notifier<List<OfficeModel>> {
  @override
  List<OfficeModel> build() => List<OfficeModel>.of(dummyOffices);

  OfficeModel? updatePrimaryOffice({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) {
    if (state.isEmpty) {
      return null;
    }

    final current = state.first;
    final updated = OfficeModel(
      id: current.id,
      name: name.trim(),
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    state = [updated, ...state.skip(1)];
    return updated;
  }
}

final officeStoreProvider =
    NotifierProvider<OfficeStoreController, List<OfficeModel>>(
      OfficeStoreController.new,
    );

final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  return OfficeRepository(ref.watch(officeStoreProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(userRepositoryProvider));
});
