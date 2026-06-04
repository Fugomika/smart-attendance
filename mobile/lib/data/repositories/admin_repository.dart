import '../../core/enums/attendance_status.dart';
import '../../core/enums/admin_attendance_status_filter.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'attendance_repository.dart';

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

class AdminAttendanceReportRow {
  const AdminAttendanceReportRow({
    required this.user,
    required this.selectedDate,
    this.attendance,
  });

  final UserModel user;
  final DateTime selectedDate;
  final AttendanceModel? attendance;

  bool get hasAttendance => attendance != null;
}

class AdminRepository {
  const AdminRepository(this._userRepository, this._attendanceRepository);

  final UserRepository _userRepository;
  final AttendanceRepository _attendanceRepository;

  Future<AdminSummary> getSummaryByDate(DateTime selectedDate) async {
    final employees = _userRepository.getAttendanceUsers(isActive: true);
    final employeeIds = employees.map((user) => user.id).toSet();
    final activeRecords = _attendanceRepository.allAttendances.where((
      attendance,
    ) {
      return employeeIds.contains(attendance.userId) &&
          AttendanceRepository.isSameDate(
            attendance.attendanceDate,
            selectedDate,
          );
    }).toList();

    final uniqueRecordedEmployeeIds = activeRecords
        .map((attendance) => attendance.userId)
        .toSet();

    final present = _countByStatuses(activeRecords, const [
      AttendanceStatus.valid,
    ]);
    final pending = _countByStatuses(activeRecords, const [
      AttendanceStatus.checkedIn,
      AttendanceStatus.pending,
    ]);
    final others = _countByStatuses(activeRecords, const [
      AttendanceStatus.sick,
      AttendanceStatus.leave,
      AttendanceStatus.holiday,
      AttendanceStatus.rejected,
    ]);
    final absent = employees.length - uniqueRecordedEmployeeIds.length;

    return AdminSummary(
      present: present,
      pending: pending,
      absent: absent,
      others: others,
      total: employees.length,
    );
  }

  Future<List<AdminAttendanceReportRow>> getAttendanceReportByDate({
    required DateTime selectedDate,
    String query = '',
    AdminAttendanceStatusFilter statusFilter = AdminAttendanceStatusFilter.all,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final users = _userRepository.getAttendanceUsers(isActive: true).where((
      user,
    ) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      return user.name.toLowerCase().contains(normalizedQuery) ||
          user.email.toLowerCase().contains(normalizedQuery);
    }).toList();

    final rows = users.map((user) {
      final attendance = _attendanceRepository.getAttendanceByDate(
        user.id,
        selectedDate,
      );

      return AdminAttendanceReportRow(
        user: user,
        selectedDate: selectedDate,
        attendance: attendance,
      );
    }).toList();

    final filteredRows = rows.where((row) {
      return _matchesReportStatusFilter(statusFilter, row.attendance);
    }).toList();

    filteredRows.sort((first, second) {
      final firstHasAttendance = first.hasAttendance ? 0 : 1;
      final secondHasAttendance = second.hasAttendance ? 0 : 1;
      if (firstHasAttendance != secondHasAttendance) {
        return firstHasAttendance.compareTo(secondHasAttendance);
      }

      return first.user.name.toLowerCase().compareTo(
        second.user.name.toLowerCase(),
      );
    });

    return filteredRows;
  }

  int _countByStatuses(
    List<AttendanceModel> attendances,
    List<AttendanceStatus> statuses,
  ) {
    return attendances
        .where((attendance) => statuses.contains(attendance.status))
        .length;
  }

  bool _matchesReportStatusFilter(
    AdminAttendanceStatusFilter filter,
    AttendanceModel? attendance,
  ) {
    if (filter == AdminAttendanceStatusFilter.all) {
      return true;
    }
    if (filter.isNotCheckedIn) {
      return attendance == null;
    }

    return attendance?.status == filter.attendanceStatus;
  }
}
