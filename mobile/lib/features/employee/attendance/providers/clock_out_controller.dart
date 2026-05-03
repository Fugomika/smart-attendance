import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/repositories/repository_providers.dart';

enum ClockOutSubmitStatus { idle, submitting, success, error }

class ClockOutSubmitState extends Equatable {
  const ClockOutSubmitState({
    required this.status,
    this.attendance,
    this.message,
  });

  const ClockOutSubmitState.idle() : this(status: ClockOutSubmitStatus.idle);

  final ClockOutSubmitStatus status;
  final AttendanceModel? attendance;
  final String? message;

  bool get isSubmitting => status == ClockOutSubmitStatus.submitting;

  @override
  List<Object?> get props => [status, attendance, message];
}

class ClockOutController extends Notifier<ClockOutSubmitState> {
  @override
  ClockOutSubmitState build() => const ClockOutSubmitState.idle();

  Future<AttendanceModel?> submit(AttendanceModel attendance) async {
    if (attendance.status != AttendanceStatus.checkedIn) {
      state = const ClockOutSubmitState(
        status: ClockOutSubmitStatus.error,
        message: 'Presensi hari ini tidak dalam status absen masuk.',
      );
      return null;
    }

    state = const ClockOutSubmitState(status: ClockOutSubmitStatus.submitting);

    try {
      final submitted = await ref
          .read(attendanceStoreProvider.notifier)
          .clockOut(attendanceId: attendance.id, clockOutTime: DateTime.now());

      state = ClockOutSubmitState(
        status: ClockOutSubmitStatus.success,
        attendance: submitted,
        message: submitted.isOutside
            ? 'Absen pulang disimpan dan menunggu validasi admin.'
            : 'Absen pulang berhasil disimpan.',
      );
      return submitted;
    } catch (_) {
      state = const ClockOutSubmitState(
        status: ClockOutSubmitStatus.error,
        message: 'Absen pulang gagal disimpan. Coba lagi.',
      );
      return null;
    }
  }
}

final clockOutControllerProvider =
    NotifierProvider<ClockOutController, ClockOutSubmitState>(
      ClockOutController.new,
    );
