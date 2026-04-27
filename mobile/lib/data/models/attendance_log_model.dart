import 'package:equatable/equatable.dart';

class AttendanceLogModel extends Equatable {
  const AttendanceLogModel({
    required this.id,
    required this.attendanceId,
    required this.action,
    required this.actorId,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String attendanceId;
  final String action;
  final String actorId;
  final DateTime createdAt;
  final String? note;

  @override
  List<Object?> get props => [
    id,
    attendanceId,
    action,
    actorId,
    createdAt,
    note,
  ];
}
