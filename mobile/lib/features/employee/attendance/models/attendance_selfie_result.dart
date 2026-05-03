import 'package:equatable/equatable.dart';

import 'attendance_location_result.dart';

class AttendanceSelfieResult extends Equatable {
  const AttendanceSelfieResult({
    required this.locationResult,
    required this.selfiePath,
    required this.capturedAt,
  });

  final AttendanceLocationResult locationResult;
  final String selfiePath;
  final DateTime capturedAt;

  @override
  List<Object?> get props => [locationResult, selfiePath, capturedAt];
}
