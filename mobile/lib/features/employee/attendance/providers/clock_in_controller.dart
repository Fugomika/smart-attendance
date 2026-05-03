import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/attendance_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/attendance_selfie_result.dart';

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
        message: 'Sesi pengguna tidak tersedia. Silakan login ulang.',
      );
      return null;
    }

    final selfiePath = result.selfiePath.trim();
    if (selfiePath.isEmpty) {
      state = const ClockInSubmitState(
        status: ClockInSubmitStatus.error,
        message: 'Foto selfie belum tersedia.',
      );
      return null;
    }

    state = const ClockInSubmitState(status: ClockInSubmitStatus.submitting);

    try {
      final now = DateTime.now();
      final locationResult = result.locationResult;
      final attendance = await ref
          .read(attendanceStoreProvider.notifier)
          .clockIn(
            userId: user.id,
            officeId: locationResult.office.id,
            attendanceDate: now,
            clockInTime: now,
            clockInLat: locationResult.userLocation.latitude,
            clockInLng: locationResult.userLocation.longitude,
            isOutside: locationResult.isOutside,
            outsideReason: locationResult.isOutside
                ? locationResult.outsideReason?.trim()
                : null,
            clockInPhotoId: selfiePath,
          );

      state = ClockInSubmitState(
        status: ClockInSubmitStatus.success,
        attendance: attendance,
        message: 'Absen masuk berhasil disimpan.',
      );
      return attendance;
    } catch (_) {
      state = const ClockInSubmitState(
        status: ClockInSubmitStatus.error,
        message: 'Absen masuk gagal disimpan. Coba lagi.',
      );
      return null;
    }
  }
}

final clockInControllerProvider =
    NotifierProvider<ClockInController, ClockInSubmitState>(
      ClockInController.new,
    );
