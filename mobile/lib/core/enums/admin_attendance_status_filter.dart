import 'attendance_status.dart';

enum AdminAttendanceStatusFilter {
  all('Semua'),
  notCheckedIn('Belum Absen'),
  checkedIn('Sudah Masuk', AttendanceStatus.checkedIn),
  pending('Pending', AttendanceStatus.pending),
  valid('Valid', AttendanceStatus.valid),
  rejected('Ditolak', AttendanceStatus.rejected),
  sick('Sakit', AttendanceStatus.sick),
  leave('Cuti', AttendanceStatus.leave),
  holiday('Libur', AttendanceStatus.holiday);

  const AdminAttendanceStatusFilter(this.label, [this.attendanceStatus]);

  final String label;
  final AttendanceStatus? attendanceStatus;

  bool get isNotCheckedIn => this == AdminAttendanceStatusFilter.notCheckedIn;
}
