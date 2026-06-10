import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../providers/employee_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/attendance_selfie_result.dart';
import 'employee_attendance_history_providers.dart';

enum ClockInSubmitStatus { idle, submitting, success, error }

class ClockInSubmitState extends Equatable {
  const ClockInSubmitState({
    required this.status,
    this.attendance,
    this.message,
  });

  const ClockInSubmitState.idle() : this(status: ClockInSubmitStatus.idle);

  final ClockInSubmitStatus status;
  final AttendanceModel? attendance;
  final String? message;

  bool get isSubmitting => status == ClockInSubmitStatus.submitting;

  @override
  List<Object?> get props => [status, attendance, message];
}

class ClockInController extends Notifier<ClockInSubmitState> {
  @override
  ClockInSubmitState build() => const ClockInSubmitState.idle();

  Future<AttendanceModel?> submit(AttendanceSelfieResult result) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const ClockInSubmitState(
        status: ClockInSubmitStatus.error,
        message: 'Sesi pengguna tidak tersedia. Silakan login ulang',
      );
      return null;
    }

    final selfiePath = result.selfiePath.trim();
    if (selfiePath.isEmpty) {
      state = const ClockInSubmitState(
        status: ClockInSubmitStatus.error,
        message: 'Foto selfie belum tersedia',
      );
      return null;
    }

    state = const ClockInSubmitState(status: ClockInSubmitStatus.submitting);

    try {
      final locationResult = result.locationResult;
      final uploadedSelfie = await ref
          .read(fileRepositoryProvider)
          .uploadAttendanceSelfie(selfiePath);
      final attendance = await ref
          .read(attendanceRepositoryProvider)
          .clockInToApi(
            userId: user.id,
            officeId: locationResult.office.id,
            clockInLat: locationResult.userLocation.latitude,
            clockInLng: locationResult.userLocation.longitude,
            isOutside: locationResult.isOutside,
            outsideReason: locationResult.isOutside
                ? locationResult.outsideReason?.trim()
                : null,
            clockInPhotoId: uploadedSelfie.id,
          );

      ref.invalidate(todayAttendanceProvider);
      ref.invalidate(employeeAttendanceHistoryProvider);
      state = ClockInSubmitState(
        status: ClockInSubmitStatus.success,
        attendance: attendance,
        message: 'Absen masuk berhasil disimpan',
      );
      return attendance;
    } on ApiException catch (error) {
      await expireSessionOnUnauthorized(ref, error);

      state = ClockInSubmitState(
        status: ClockInSubmitStatus.error,
        message: _clockInErrorMessage(error),
      );
      return null;
    } catch (_) {
      state = const ClockInSubmitState(
        status: ClockInSubmitStatus.error,
        message: 'Absen masuk gagal disimpan. Coba lagi',
      );
      return null;
    }
  }

  String _clockInErrorMessage(ApiException error) {
    return switch (error.statusCode) {
      401 => 'Sesi berakhir. Silakan login kembali',
      404 => 'Data kantor atau foto selfie tidak ditemukan',
      409 => 'Kamu sudah absen masuk hari ini',
      422 => error.displayMessage,
      _ => error.displayMessage,
    };
  }
}

final clockInControllerProvider =
    NotifierProvider<ClockInController, ClockInSubmitState>(
      ClockInController.new,
    );
