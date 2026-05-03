import '../../core/enums/attendance_status.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  const AttendanceRepository(this._attendances);

  final List<AttendanceModel> _attendances;

  AttendanceModel? getTodayAttendance(String userId) {
    return getAttendanceByDate(userId, DateTime.now());
  }

  AttendanceModel? getAttendanceByDate(String userId, DateTime date) {
    for (final attendance in _attendances) {
      final sameUser = attendance.userId == userId;
      final sameDate = isSameDate(attendance.attendanceDate, date);
      if (sameUser && sameDate) {
        return attendance;
      }
    }

    return null;
  }

  AttendanceModel? getAttendanceById(String id) {
    for (final attendance in _attendances) {
      if (attendance.id == id) {
        return attendance;
      }
    }

    return null;
  }

  List<AttendanceModel> getHistoryByUser(String userId) {
    return _attendances
        .where((attendance) => attendance.userId == userId)
        .toList();
  }

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
    final existing = getAttendanceByDate(userId, attendanceDate);
    final date = dateOnly(attendanceDate);

    return AttendanceModel(
      id:
          existing?.id ??
          'attendance-${userId}-${date.year}${date.month}${date.day}',
      userId: userId,
      officeId: officeId,
      attendanceDate: date,
      status: AttendanceStatus.checkedIn,
      clockInTime: clockInTime,
      clockInLat: clockInLat,
      clockInLng: clockInLng,
      isOutside: isOutside,
      outsideReason: isOutside ? outsideReason : null,
      clockInPhotoId: clockInPhotoId,
    );
  }

  Future<AttendanceModel> clockOut({
    required String attendanceId,
    required DateTime clockOutTime,
  }) async {
    final existing = getAttendanceById(attendanceId);
    if (existing == null) {
      throw StateError('Attendance tidak ditemukan.');
    }
    if (existing.status != AttendanceStatus.checkedIn) {
      throw StateError('Attendance tidak dalam status CHECKED_IN.');
    }

    return AttendanceModel(
      id: existing.id,
      userId: existing.userId,
      officeId: existing.officeId,
      attendanceDate: existing.attendanceDate,
      status: existing.isOutside
          ? AttendanceStatus.pending
          : AttendanceStatus.valid,
      clockInTime: existing.clockInTime,
      clockOutTime: clockOutTime,
      clockInLat: existing.clockInLat,
      clockInLng: existing.clockInLng,
      isOutside: existing.isOutside,
      outsideReason: existing.outsideReason,
      clockInPhotoId: existing.clockInPhotoId,
    );
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
