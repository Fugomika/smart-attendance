import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/attendance_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../providers/employee_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import 'employee_attendance_history_providers.dart';

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
        message: 'Presensi hari ini tidak dalam status absen masuk',
      );
      return null;
    }

    state = const ClockOutSubmitState(status: ClockOutSubmitStatus.submitting);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = const ClockOutSubmitState(
          status: ClockOutSubmitStatus.error,
          message: 'Sesi pengguna tidak tersedia. Silakan login ulang',
        );
        return null;
      }

      final submitted = await ref
          .read(attendanceRepositoryProvider)
          .clockOutToApi(attendanceId: attendance.id, userId: user.id);

      ref.invalidate(todayAttendanceProvider);
      ref.invalidate(employeeAttendanceHistoryProvider);
      ref.invalidate(employeeAttendanceDetailProvider(attendance.id));
      state = ClockOutSubmitState(
        status: ClockOutSubmitStatus.success,
        attendance: submitted,
        message: submitted.isOutside
            ? 'Absen pulang disimpan dan menunggu validasi admin'
            : 'Absen pulang berhasil disimpan',
      );
      return submitted;
    } on ApiException catch (error) {
      await expireSessionOnUnauthorized(ref, error);

      state = ClockOutSubmitState(
        status: ClockOutSubmitStatus.error,
        message: _clockOutErrorMessage(error),
      );
      return null;
    } catch (_) {
      state = const ClockOutSubmitState(
        status: ClockOutSubmitStatus.error,
        message: 'Absen pulang gagal disimpan. Coba lagi',
      );
      return null;
    }
  }

  String _clockOutErrorMessage(ApiException error) {
    return switch (error.statusCode) {
      400 => error.displayMessage,
      401 => 'Sesi berakhir. Silakan login kembali',
      403 => 'Presensi ini tidak dapat diakses oleh akun kamu',
      404 => 'Data presensi tidak ditemukan',
      422 => error.displayMessage,
      _ => error.displayMessage,
    };
  }
}

final clockOutControllerProvider =
    NotifierProvider<ClockOutController, ClockOutSubmitState>(
      ClockOutController.new,
    );
