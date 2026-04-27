import '../../core/enums/attendance_status.dart';
import '../dummy/dummy_attendances.dart';
import '../repositories/user_repository.dart';

class AdminSummary {
  const AdminSummary({
    required this.present,
    required this.pending,
    required this.absent,
    required this.others,
    required this.total,
  });

  final int present;
  final int pending;
  final int absent;
  final int others;
  final int total;
}

class AdminRepository {
  const AdminRepository(this._userRepository);

  final UserRepository _userRepository;

  AdminSummary getTodaySummary() {
    final employees = _userRepository.getEmployees(isActive: true);
    final today = DateTime(2026, 4, 20);
    final todayRecords = dummyAttendances.where((attendance) {
      return attendance.attendanceDate.year == today.year &&
          attendance.attendanceDate.month == today.month &&
          attendance.attendanceDate.day == today.day;
    }).toList();

    final employeeIds = employees.map((user) => user.id).toSet();
    final activeRecords = todayRecords
        .where((attendance) => employeeIds.contains(attendance.userId))
        .toList();

    final present = activeRecords
        .where((attendance) => attendance.status == AttendanceStatus.valid)
        .length;
    final pending = activeRecords
        .where((attendance) => attendance.status == AttendanceStatus.pending)
        .length;
    final others = activeRecords.where((attendance) {
      return attendance.status == AttendanceStatus.sick ||
          attendance.status == AttendanceStatus.leave ||
          attendance.status == AttendanceStatus.holiday ||
          attendance.status == AttendanceStatus.rejected;
    }).length;
    final absent = employees.length - activeRecords.length;

    return AdminSummary(
      present: present,
      pending: pending,
      absent: absent,
      others: others,
      total: employees.length,
    );
  }
}
