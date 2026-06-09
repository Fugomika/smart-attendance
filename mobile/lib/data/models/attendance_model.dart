import 'package:equatable/equatable.dart';

import '../../core/enums/attendance_status.dart';
import '../../core/utils/api_date_time_parser.dart';

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
    this.rejectNote,
    this.clockInPhotoId,
    this.officeName,
    this.officeLatitude,
    this.officeLongitude,
    this.officeRadiusMeter,
    this.selfieUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final attendanceDate = ApiDateTimeParser.dateOnly(json['attendanceDate']);
    if (attendanceDate == null) {
      throw const FormatException('Invalid attendance date.');
    }

    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      userId:
          json['userId']?.toString() ??
          json['UserId']?.toString() ??
          currentUserId ??
          '',
      officeId:
          json['officeId']?.toString() ?? json['OfficeId']?.toString() ?? '',
      attendanceDate: attendanceDate,
      status: _parseStatus(json['status']),
      clockInTime: ApiDateTimeParser.timestamp(json['clockInTime']),
      clockOutTime: ApiDateTimeParser.timestamp(json['clockOutTime']),
      clockInLat: _parseDouble(json['clockInLat']),
      clockInLng: _parseDouble(json['clockInLng']),
      isOutside: _parseBool(json['isOutside']),
      outsideReason: json['outsideReason']?.toString(),
      rejectNote: json['rejectNote']?.toString(),
      clockInPhotoId: json['clockInPhotoId']?.toString(),
      officeName: json['officeName']?.toString(),
      officeLatitude: _parseDouble(json['officeLatitude']),
      officeLongitude: _parseDouble(json['officeLongitude']),
      officeRadiusMeter: _parseDouble(json['officeRadiusMeter']),
      selfieUrl: json['selfieUrl']?.toString(),
      createdAt: ApiDateTimeParser.timestamp(json['createdAt']),
      updatedAt: ApiDateTimeParser.timestamp(json['updatedAt']),
    );
  }

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
  final String? rejectNote;
  final String? clockInPhotoId;
  final String? officeName;
  final double? officeLatitude;
  final double? officeLongitude;
  final double? officeRadiusMeter;
  final String? selfieUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    rejectNote,
    clockInPhotoId,
    officeName,
    officeLatitude,
    officeLongitude,
    officeRadiusMeter,
    selfieUrl,
    createdAt,
    updatedAt,
  ];
}

AttendanceStatus _parseStatus(Object? value) {
  return switch (value?.toString().toUpperCase()) {
    'CHECKED_IN' => AttendanceStatus.checkedIn,
    'PENDING' => AttendanceStatus.pending,
    'VALID' => AttendanceStatus.valid,
    'REJECTED' => AttendanceStatus.rejected,
    'SICK' => AttendanceStatus.sick,
    'LEAVE' => AttendanceStatus.leave,
    'HOLIDAY' => AttendanceStatus.holiday,
    _ => AttendanceStatus.checkedIn,
  };
}

double? _parseDouble(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

bool _parseBool(Object? value) {
  if (value is bool) {
    return value;
  }

  final raw = value?.toString().toLowerCase();
  return raw == 'true' || raw == '1';
}
