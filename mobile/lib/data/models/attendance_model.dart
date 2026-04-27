import 'package:equatable/equatable.dart';

import '../../core/enums/attendance_status.dart';

class AttendanceModel extends Equatable {
  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.officeId,
    required this.attendanceDate,
    required this.status,
    this.clockInTime,
    this.clockOutTime,
    this.clockInLat,
    this.clockInLng,
    this.isOutside = false,
    this.outsideReason,
    this.clockInPhotoId,
  });

  final String id;
  final String userId;
  final String officeId;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final double? clockInLat;
  final double? clockInLng;
  final bool isOutside;
  final String? outsideReason;
  final String? clockInPhotoId;

  @override
  List<Object?> get props => [
    id,
    userId,
    officeId,
    attendanceDate,
    status,
    clockInTime,
    clockOutTime,
    clockInLat,
    clockInLng,
    isOutside,
    outsideReason,
    clockInPhotoId,
  ];
}
