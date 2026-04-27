import '../dummy/dummy_attendances.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  const AttendanceRepository();

  AttendanceModel? getTodayAttendance(String userId) {
    return getAttendanceByDate(userId, DateTime(2026, 4, 20));
  }

  AttendanceModel? getAttendanceByDate(String userId, DateTime date) {
    for (final attendance in dummyAttendances) {
      final sameUser = attendance.userId == userId;
      final sameDate =
          attendance.attendanceDate.year == date.year &&
          attendance.attendanceDate.month == date.month &&
          attendance.attendanceDate.day == date.day;
      if (sameUser && sameDate) {
        return attendance;
      }
    }

    return null;
  }

  List<AttendanceModel> getHistoryByUser(String userId) {
    return dummyAttendances
        .where((attendance) => attendance.userId == userId)
        .toList();
  }
}
