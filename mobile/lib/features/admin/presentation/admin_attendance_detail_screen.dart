import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/enums/attendance_status.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/utils/app_date_time_formatter.dart';
import '../../../core/utils/attendance_location_detail.dart';
import '../../../core/utils/attendance_status_mapper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/office_model.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/attendance_info_row.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/profile_avatar_view.dart';
import '../../../shared/widgets/status_badge.dart';
import 'widgets/admin_user_status_badge.dart';
import '../providers/admin_providers.dart';

class AdminAttendanceDetailScreen extends ConsumerWidget {
  const AdminAttendanceDetailScreen({required this.attendanceId, super.key});

  final String attendanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(adminAttendanceDetailProvider(attendanceId));
    final employee = attendance == null
        ? null
        : ref.watch(adminAttendanceUserProvider(attendance.userId));
    final office = attendance == null
        ? null
        : ref.watch(adminAttendanceOfficeProvider(attendance.officeId));

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
                      _EmployeeCard(employee: employee),
                      const SizedBox(height: AppSpacing.lg),
                      _StatusOverview(attendance: attendance),
                      const SizedBox(height: AppSpacing.lg),
                      _AttendanceDetailCard(
                        attendance: attendance,
                        office: office,
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
                        _AdminValidationInfoCard(attendance: attendance),
                      ],
                      if (attendance.status == AttendanceStatus.pending) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ValidationActionCard(attendanceId: attendance.id),
                      ],
                    ],
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

    context.go(RouteNames.adminEmployees);
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});

  final UserModel? employee;

  @override
  Widget build(BuildContext context) {
    if (employee == null) {
      return const AppCard(
        child: AttendanceInfoRow(
          icon: Icons.person_search_rounded,
          label: 'Karyawan',
          value: 'Data karyawan tidak tersedia.',
        ),
      );
    }

    final jobTitle = employee!.jabatan?.trim().isNotEmpty == true
        ? employee!.jabatan!
        : 'Jabatan belum tersedia';

    return AppCard(
      backgroundColor: AppColors.softBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatarView(
            name: employee!.name,
            photoPath: employee!.photoId,
            size: 64,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee!.name,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  jobTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  employee!.email,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _RoleChip(role: employee!.role),
                    AdminUserStatusBadge(isActive: employee!.isActive),
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

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.employee => 'Karyawan',
      UserRole.admin => 'Admin',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
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

class _ValidationActionCard extends ConsumerWidget {
  const _ValidationActionCard({required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aksi Validasi',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Presensi ini sedang menunggu keputusan admin.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Tolak',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.medium,
                  onPressed: () => _confirmReject(context, ref),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Setujui',
                  variant: AppButtonVariant.success,
                  size: AppButtonSize.medium,
                  onPressed: () => _confirmApprove(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmApprove(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: 'Setujui Presensi?',
      message: 'Status presensi akan diubah menjadi Valid.',
      confirmLabel: 'Setujui',
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(adminAttendanceActionProvider)
          .approveAttendance(attendanceId);
      if (context.mounted) {
        AppSnackBar.success(context, 'Presensi berhasil disetujui.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Presensi gagal disetujui.');
      }
    }
  }

  Future<void> _confirmReject(BuildContext context, WidgetRef ref) async {
    final noteController = TextEditingController();
    final decision = await showDialog<_RejectDecision>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tolak Presensi?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Status presensi akan diubah menjadi Ditolak.'),
                const SizedBox(height: AppSpacing.md),
                AppFormField(
                  label: 'Catatan Penolakan',
                  hint: 'Tambahkan alasan jika diperlukan',
                  controller: noteController,
                  prefixIcon: Icons.edit_note_rounded,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 255,
                  helperText: 'Opsional, maksimal 255 karakter.',
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(_RejectDecision(note: noteController.text.trim()));
              },
              child: const Text(
                'Tolak',
                style: TextStyle(
                  color: AppColors.dangerDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    noteController.dispose();

    if (decision == null) {
      return;
    }

    try {
      await ref
          .read(adminAttendanceActionProvider)
          .rejectAttendance(attendanceId, note: decision.note);
      if (context.mounted) {
        AppSnackBar.success(context, 'Presensi berhasil ditolak.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Presensi gagal ditolak.');
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: isDanger ? AppColors.dangerDark : AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RejectDecision {
  const _RejectDecision({required this.note});

  final String note;
}

bool _shouldShowOutsideReason(AttendanceModel attendance) {
  final reason = attendance.outsideReason;
  return attendance.isOutside && reason != null && reason.trim().isNotEmpty;
}

bool _shouldShowAdminValidationInfo(AttendanceStatus status) {
  return status == AttendanceStatus.pending ||
      status == AttendanceStatus.rejected;
}
