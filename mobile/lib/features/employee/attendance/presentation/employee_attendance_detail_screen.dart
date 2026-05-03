import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/utils/app_date_time_formatter.dart';
import '../../../../core/utils/attendance_status_mapper.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_system_overlay.dart';
import '../../../../shared/widgets/attendance_info_row.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/employee_attendance_history_providers.dart';

class EmployeeAttendanceDetailScreen extends ConsumerWidget {
  const EmployeeAttendanceDetailScreen({required this.attendanceId, super.key});

  final String attendanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(
      employeeAttendanceDetailProvider(attendanceId),
    );
    final office = attendance == null
        ? null
        : ref.watch(attendanceOfficeProvider(attendance.officeId));

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.surface,
      navigationBarColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(RouteNames.employeeHistory),
          ),
          title: Text('Detail Presensi', style: AppTextStyles.h2),
        ),
        body: SafeArea(
          child: attendance == null
              ? const EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'Data Tidak Ditemukan',
                  message: 'Detail presensi ini tidak tersedia.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusOverview(attendance: attendance),
                      const SizedBox(height: AppSpacing.lg),
                      _AttendanceDetailCard(
                        attendance: attendance,
                        officeName: office?.name ?? '-',
                      ),
                      if (_shouldShowOutsideReason(attendance)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _OutsideReasonCard(reason: attendance.outsideReason!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _SelfiePlaceholderCard(
                        photoId: attendance.clockInPhotoId,
                      ),
                      if (_shouldShowAdminValidationInfo(
                        attendance.status,
                      )) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _AdminValidationInfoCard(status: attendance.status),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.attendance});

  final AttendanceModel attendance;

  @override
  Widget build(BuildContext context) {
    final statusStyle = AttendanceStatusMapper.fromAttendanceStatus(
      attendance.status,
    );

    return AppCard(
      backgroundColor: AppColors.softBlue,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Presensi', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(style: statusStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceDetailCard extends StatelessWidget {
  const _AttendanceDetailCard({
    required this.attendance,
    required this.officeName,
  });

  final AttendanceModel attendance;
  final String officeName;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          AttendanceInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: AppDateTimeFormatter.dateLong(attendance.attendanceDate),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceInfoRow(
            icon: Icons.login_rounded,
            label: 'Jam Masuk',
            value: AppDateTimeFormatter.time(attendance.clockInTime),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceInfoRow(
            icon: Icons.logout_rounded,
            label: 'Jam Pulang',
            value: AppDateTimeFormatter.time(attendance.clockOutTime),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Kantor/Lokasi',
            value: officeName,
          ),
        ],
      ),
    );
  }
}

class _OutsideReasonCard extends StatelessWidget {
  const _OutsideReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: AttendanceInfoRow(
        icon: Icons.edit_note_rounded,
        label: 'Alasan di Luar Area',
        value: reason,
      ),
    );
  }
}

class _SelfiePlaceholderCard extends StatelessWidget {
  const _SelfiePlaceholderCard({required this.photoId});

  final String? photoId;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoId != null && photoId!.trim().isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foto Selfie', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 44,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasPhoto ? 'Placeholder foto: $photoId' : 'Foto belum ada',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminValidationInfoCard extends StatelessWidget {
  const _AdminValidationInfoCard({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final isRejected = status == AttendanceStatus.rejected;

    return AppCard(
      backgroundColor: isRejected
          ? AppColors.dangerLight.withValues(alpha: 0.24)
          : AppColors.warningLight.withValues(alpha: 0.34),
      child: AttendanceInfoRow(
        icon: isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
        label: 'Validasi Admin',
        value: isRejected
            ? 'Presensi ditolak oleh admin. Catatan detail belum tersedia di data dummy.'
            : 'Presensi sedang menunggu validasi admin.',
        valueColor: isRejected ? AppColors.dangerDark : AppColors.warningDark,
      ),
    );
  }
}

bool _shouldShowOutsideReason(AttendanceModel attendance) {
  final reason = attendance.outsideReason;
  return attendance.isOutside && reason != null && reason.trim().isNotEmpty;
}

bool _shouldShowAdminValidationInfo(AttendanceStatus status) {
  return status == AttendanceStatus.pending ||
      status == AttendanceStatus.rejected;
}
