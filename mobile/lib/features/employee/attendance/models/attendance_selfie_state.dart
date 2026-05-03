import 'package:equatable/equatable.dart';

enum AttendanceSelfieStatus {
  initializing,
  ready,
  capturing,
  captured,
  permissionDenied,
  cameraUnavailable,
  error,
}

class AttendanceSelfieState extends Equatable {
  const AttendanceSelfieState({
    required this.status,
    this.selfiePath,
    this.capturedAt,
    this.message,
  });

  const AttendanceSelfieState.initializing()
    : this(
        status: AttendanceSelfieStatus.initializing,
        message: 'Menyiapkan kamera...',
      );

  final AttendanceSelfieStatus status;
  final String? selfiePath;
  final DateTime? capturedAt;
  final String? message;

  bool get isInitializing => status == AttendanceSelfieStatus.initializing;

  bool get isReady => status == AttendanceSelfieStatus.ready;

  bool get isCapturing => status == AttendanceSelfieStatus.capturing;

  bool get hasCapturedPhoto =>
      status == AttendanceSelfieStatus.captured && selfiePath != null;

  bool get canContinue => hasCapturedPhoto;

  AttendanceSelfieState copyWith({
    AttendanceSelfieStatus? status,
    String? selfiePath,
    DateTime? capturedAt,
    String? message,
    bool clearSelfie = false,
    bool clearMessage = false,
  }) {
    return AttendanceSelfieState(
      status: status ?? this.status,
      selfiePath: clearSelfie ? null : selfiePath ?? this.selfiePath,
      capturedAt: clearSelfie ? null : capturedAt ?? this.capturedAt,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, selfiePath, capturedAt, message];
}
