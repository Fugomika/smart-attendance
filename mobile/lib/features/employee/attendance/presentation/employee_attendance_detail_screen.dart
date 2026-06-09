import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/enums/attendance_status.dart';
import '../../../../core/utils/app_date_time_formatter.dart';
import '../../../../core/utils/attendance_location_detail.dart';
import '../../../../core/utils/attendance_status_mapper.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/office_model.dart';
import '../../../../shared/utils/app_snack_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_system_overlay.dart';
import '../../../../shared/widgets/attendance_info_row.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/employee_attendance_history_providers.dart';

class EmployeeAttendanceDetailScreen extends ConsumerWidget {
  const EmployeeAttendanceDetailScreen({required this.attendanceId, super.key});

  final String attendanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(
      employeeAttendanceDetailProvider(attendanceId),
    );

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
            onPressed: () => _goBack(context),
          ),
          title: Text('Detail Presensi', style: AppTextStyles.h2),
        ),
        body: SafeArea(
          child: attendanceAsync.when(
            loading: () =>
                const LoadingState(message: 'Mengambil detail presensi...'),
            error: (error, stackTrace) => EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Detail Belum Tersedia',
              message: 'Detail presensi belum bisa dimuat.',
              action: AppButton(
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  ref.invalidate(
                    employeeAttendanceDetailProvider(attendanceId),
                  );
                },
              ),
            ),
            data: (attendance) => attendance == null
                ? const EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'Data Tidak Ditemukan',
                    message: 'Detail presensi ini tidak tersedia.',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      employeeAttendanceDetailProvider(attendanceId).future,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatusOverview(attendance: attendance),
                          const SizedBox(height: AppSpacing.lg),
                          _AttendanceDetailCard(
                            attendance: attendance,
                            office: null,
                          ),
                          if (_shouldShowOutsideReason(attendance)) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _OutsideReasonCard(
                              reason: attendance.outsideReason!,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          _SelfiePlaceholderCard(
                            photoId: attendance.clockInPhotoId,
                            selfieUrl: attendance.selfieUrl,
                          ),
                          if (_shouldShowAdminValidationInfo(
                            attendance.status,
                          )) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _AdminValidationInfoCard(attendance: attendance),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(RouteNames.employeeHistory);
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
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusBadge(style: statusStyle),
                    if (attendance.isOutside) const _OutsideAreaBadge(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceDetailCard extends StatelessWidget {
  const _AttendanceDetailCard({required this.attendance, required this.office});

  final AttendanceModel attendance;
  final OfficeModel? office;

  @override
  Widget build(BuildContext context) {
    final location = AttendanceLocationDetail.resolve(
      attendance: attendance,
      office: office,
    );

    return AppCard(
      child: Column(
        children: [
          AttendanceInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: _formatShortDate(attendance.attendanceDate),
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
            label: 'Kantor',
            value: location.officeName,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceInfoRow(
            icon: Icons.radar_rounded,
            label: 'Radius Kantor',
            value: location.radiusLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceInfoRow(
            icon: Icons.my_location_rounded,
            label: 'Koordinat Presensi',
            value: location.coordinateLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceInfoRow(
            icon: Icons.route_rounded,
            label: 'Jarak dari Kantor',
            value: location.distanceLabel,
          ),
          if (location.googleMapsUri != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Buka di Google Maps',
              icon: Icons.map_outlined,
              size: AppButtonSize.medium,
              variant: AppButtonVariant.secondary,
              onPressed: () => _openMaps(context, location.googleMapsUri!),
            ),
          ],
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _openMaps(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppSnackBar.error(context, 'Google Maps tidak bisa dibuka.');
    }
  }
}

class _OutsideAreaBadge extends StatelessWidget {
  const _OutsideAreaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.warning),
      ),
      child: Text(
        'Di Luar Area',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.warningDark,
          fontWeight: FontWeight.w700,
        ),
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
  const _SelfiePlaceholderCard({
    required this.photoId,
    required this.selfieUrl,
  });

  final String? photoId;
  final String? selfieUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoId != null && photoId!.trim().isNotEmpty;
    final hasSelfieUrl = selfieUrl != null && selfieUrl!.trim().isNotEmpty;

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
            clipBehavior: Clip.antiAlias,
            child: hasSelfieUrl
                ? Image.network(
                    selfieUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _SelfieEmptyState(
                        message: hasPhoto
                            ? 'Foto belum bisa dimuat.'
                            : 'Foto belum ada',
                      );
                    },
                  )
                : _SelfieEmptyState(
                    message: hasPhoto
                        ? 'Foto belum bisa dimuat.'
                        : 'Foto belum ada',
                  ),
          ),
        ],
      ),
    );
  }
}

class _SelfieEmptyState extends StatelessWidget {
  const _SelfieEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.photo_camera_outlined,
          size: 44,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AdminValidationInfoCard extends StatelessWidget {
  const _AdminValidationInfoCard({required this.attendance});

  final AttendanceModel attendance;

  @override
  Widget build(BuildContext context) {
    final isRejected = attendance.status == AttendanceStatus.rejected;
    final rejectNote = attendance.rejectNote?.trim();

    return AppCard(
      backgroundColor: isRejected
          ? AppColors.dangerLight.withValues(alpha: 0.24)
          : AppColors.warningLight.withValues(alpha: 0.34),
      child: AttendanceInfoRow(
        icon: isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
        label: 'Validasi Admin',
        value: isRejected
            ? rejectNote?.isNotEmpty == true
                  ? 'Presensi ditolak: $rejectNote'
                  : 'Presensi ditolak oleh admin.'
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
