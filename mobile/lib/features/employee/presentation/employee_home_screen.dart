import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/enums/attendance_status.dart';
import '../../../core/utils/app_date_time_formatter.dart';
import '../../../data/models/attendance_model.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/attendance_info_row.dart';
import '../../../shared/widgets/profile_avatar_view.dart';
import '../attendance/providers/clock_out_controller.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_controller.dart';
import '../providers/employee_providers.dart';
import 'employee_home_status_view_data.dart';

class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});

  static final DateTime _fallbackAttendanceDate = DateTime(2026, 4, 20);

  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen> {
  _DebugAttendancePreview _debugAttendancePreview =
      _DebugAttendancePreview.live;
  _DebugGreetingPreview _debugGreetingPreview = _DebugGreetingPreview.current;
  bool _useLongDebugLocation = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileControllerProvider);
    final attendance = ref.watch(todayAttendanceProvider);
    final office = ref.watch(todayAttendanceOfficeProvider);
    final displayName = profile?.name ?? user?.name ?? 'Karyawan';
    final displayPhotoPath = profile?.photoPath ?? user?.photoId;
    final liveAttendanceDate = DateTime.now();
    final previewAttendanceDate =
        _debugAttendancePreview == _DebugAttendancePreview.live
        ? liveAttendanceDate
        : EmployeeHomeScreen._fallbackAttendanceDate;
    final effectiveAttendance = _debugAttendancePreview.resolve(
      liveAttendance: attendance,
      date: previewAttendanceDate,
      userId: user?.id ?? 'debug-user',
    );
    final attendanceDate =
        effectiveAttendance?.attendanceDate ?? previewAttendanceDate;
    final viewData = EmployeeHomeStatusMapper.fromAttendance(
      effectiveAttendance,
      locationLabel: _debugLocationLabel(office?.name),
    );

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.background,
      navigationBarColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(
                  name: displayName,
                  photoPath: displayPhotoPath,
                  greeting: _greetingFor(
                    attendanceDate,
                    hour: _debugGreetingPreview.hour,
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.lg), //mmin
                  _DebugPreviewPanel(
                    attendancePreview: _debugAttendancePreview,
                    greetingPreview: _debugGreetingPreview,
                    onAttendanceChanged: (value) {
                      setState(() {
                        _debugAttendancePreview = value;
                      });
                    },
                    onGreetingChanged: (value) {
                      setState(() {
                        _debugGreetingPreview = value;
                      });
                    },
                    useLongLocation: _useLongDebugLocation,
                    onLongLocationChanged: (value) {
                      setState(() {
                        _useLongDebugLocation = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg), //main
                _StatusCard(
                  viewData: viewData,
                  dateLabel: _formatDate(attendanceDate),
                ),
                if (viewData.hasCta) ...[
                  const SizedBox(height: AppSpacing.lg), //main
                  _AttendanceCtaCard(
                    viewData: viewData,
                    onPressed: () =>
                        _handleCta(context, viewData.cta!, effectiveAttendance),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg), //main
                _SummaryCard(viewData: viewData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCta(
    BuildContext context,
    EmployeeHomeCta cta,
    AttendanceModel? attendance,
  ) {
    if (cta == EmployeeHomeCta.clockIn) {
      context.go(RouteNames.employeeAttendanceLocation);
      return;
    }

    if (attendance == null || attendance.status != AttendanceStatus.checkedIn) {
      AppSnackBar.error(
        context,
        'Presensi hari ini belum siap untuk absen pulang.',
      );
      return;
    }

    _showClockOutConfirmation(context, attendance);
  }

  void _showClockOutConfirmation(
    BuildContext context,
    AttendanceModel attendance,
  ) {
    final previewClockOutTime = DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ClockOutConfirmationSheet(
          attendance: attendance,
          previewClockOutTime: previewClockOutTime,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onConfirm: () async {
            final submitted = await ref
                .read(clockOutControllerProvider.notifier)
                .submit(attendance);

            if (!context.mounted) {
              return;
            }

            if (submitted == null) {
              final message =
                  ref.read(clockOutControllerProvider).message ??
                  'Absen pulang gagal disimpan. Coba lagi.';
              AppSnackBar.error(context, message);
              return;
            }

            if (!sheetContext.mounted) {
              return;
            }

            Navigator.of(sheetContext).pop();
            AppSnackBar.success(
              context,
              submitted.isOutside
                  ? 'Absen pulang tersimpan dan menunggu validasi admin.'
                  : 'Absen pulang berhasil disimpan.',
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  static String _greetingFor(DateTime date, {int? hour}) {
    final resolvedHour = hour ?? DateTime.now().hour;
    final greetings = switch (resolvedHour) {
      >= 4 && < 11 => const [
        'Selamat pagi, tetap produktif.',
        'Pagi, semoga harimu lancar.',
        'Selamat pagi, mulai hari dengan fokus.',
      ],
      >= 11 && < 15 => const [
        'Selamat siang, tetap fokus.',
        'Siang, jaga ritme kerjamu.',
        'Selamat siang, lanjutkan progresmu.',
      ],
      >= 15 && < 18 => const [
        'Selamat sore, cek presensimu.',
        'Sore, tuntaskan hari dengan baik.',
        'Selamat sore, pastikan presensimu aman.',
      ],
      _ => const [
        'Selamat malam, presensi tetap aman.',
        'Malam, jangan lupa cek presensimu.',
        'Malam, pastikan presensimu aman.',
      ],
    };

    return greetings[date.day % greetings.length];
  }

  String _debugLocationLabel(String? liveOfficeName) {
    if (kDebugMode && _useLongDebugLocation) {
      return 'Jl. Jenderal Sudirman Kav. 52-53, Senayan, Kebayoran Baru, Jakarta Selatan';
    }

    return liveOfficeName ?? _debugAttendancePreview.locationLabel;
  }
}

enum _DebugAttendancePreview {
  live('Dummy Data'),
  notCheckedIn('Belum Absen'),
  checkedIn('Sudah Masuk'),
  checkedInOutside('Di Luar Kantor'),
  pending('Menunggu Validasi'),
  valid('Selesai'),
  rejected('Ditolak'),
  sick('Sakit'),
  leave('Cuti'),
  holiday('Hari Libur');

  const _DebugAttendancePreview(this.label);

  final String label;

  String get locationLabel {
    return switch (this) {
      _DebugAttendancePreview.notCheckedIn => '-',
      _DebugAttendancePreview.live => '-',
      _ => 'Kantor Pusat',
    };
  }

  AttendanceModel? resolve({
    required AttendanceModel? liveAttendance,
    required DateTime date,
    required String userId,
  }) {
    if (this == _DebugAttendancePreview.live) {
      return liveAttendance;
    }
    if (this == _DebugAttendancePreview.notCheckedIn) {
      return null;
    }

    return AttendanceModel(
      id: 'debug-${name.toLowerCase()}',
      userId: userId,
      officeId: 'office-1',
      attendanceDate: date,
      status: _status,
      clockInTime: _hasClockIn
          ? DateTime(date.year, date.month, date.day, 8)
          : null,
      clockOutTime: _hasClockOut
          ? DateTime(date.year, date.month, date.day, 17)
          : null,
      isOutside: this == _DebugAttendancePreview.checkedInOutside,
      outsideReason: this == _DebugAttendancePreview.checkedInOutside
          ? 'Preview debug presensi luar kantor.'
          : null,
    );
  }

  AttendanceStatus get _status {
    return switch (this) {
      _DebugAttendancePreview.checkedIn ||
      _DebugAttendancePreview.checkedInOutside => AttendanceStatus.checkedIn,
      _DebugAttendancePreview.pending => AttendanceStatus.pending,
      _DebugAttendancePreview.valid => AttendanceStatus.valid,
      _DebugAttendancePreview.rejected => AttendanceStatus.rejected,
      _DebugAttendancePreview.sick => AttendanceStatus.sick,
      _DebugAttendancePreview.leave => AttendanceStatus.leave,
      _DebugAttendancePreview.holiday => AttendanceStatus.holiday,
      _DebugAttendancePreview.live ||
      _DebugAttendancePreview.notCheckedIn => AttendanceStatus.checkedIn,
    };
  }

  bool get _hasClockIn {
    return switch (this) {
      _DebugAttendancePreview.sick ||
      _DebugAttendancePreview.leave ||
      _DebugAttendancePreview.holiday => false,
      _DebugAttendancePreview.live ||
      _DebugAttendancePreview.notCheckedIn => false,
      _ => true,
    };
  }

  bool get _hasClockOut {
    return switch (this) {
      _DebugAttendancePreview.pending ||
      _DebugAttendancePreview.valid ||
      _DebugAttendancePreview.rejected => true,
      _ => false,
    };
  }
}

enum _DebugGreetingPreview {
  current('Waktu Sekarang', null),
  morning('Pagi', 8),
  noon('Siang', 12),
  afternoon('Sore', 16),
  night('Malam', 20);

  const _DebugGreetingPreview(this.label, this.hour);

  final String label;
  final int? hour;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.greeting,
    this.photoPath,
  });

  final String name;
  final String greeting;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatarView(name: name, photoPath: photoPath, size: 56),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                greeting,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 44,
          width: 44,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () {
                AppSnackBar.info(
                  context,
                  'Notifikasi akan dibuat di batch nanti.',
                );
              },
              child: const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugPreviewPanel extends StatelessWidget {
  const _DebugPreviewPanel({
    required this.attendancePreview,
    required this.greetingPreview,
    required this.onAttendanceChanged,
    required this.onGreetingChanged,
    required this.useLongLocation,
    required this.onLongLocationChanged,
  });

  final _DebugAttendancePreview attendancePreview;
  final _DebugGreetingPreview greetingPreview;
  final ValueChanged<_DebugAttendancePreview> onAttendanceChanged;
  final ValueChanged<_DebugGreetingPreview> onGreetingChanged;
  final bool useLongLocation;
  final ValueChanged<bool> onLongLocationChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.softBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Preview',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _DebugDropdown<_DebugAttendancePreview>(
                  label: 'Status',
                  value: attendancePreview,
                  values: _DebugAttendancePreview.values,
                  itemLabel: (value) => value.label,
                  onChanged: onAttendanceChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DebugDropdown<_DebugGreetingPreview>(
                  label: 'Greeting',
                  value: greetingPreview,
                  values: _DebugGreetingPreview.values,
                  itemLabel: (value) => value.label,
                  onChanged: onGreetingChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          CheckboxListTile(
            value: useLongLocation,
            onChanged: (value) => onLongLocationChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Preview alamat panjang',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugDropdown<T> extends StatelessWidget {
  const _DebugDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      items: values.map((value) {
        return DropdownMenuItem<T>(
          value: value,
          child: Text(
            itemLabel(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.viewData, required this.dateLabel});

  final EmployeeHomeStatusViewData viewData;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Hari Ini',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
                size: 15,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  dateLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 58,
                decoration: BoxDecoration(
                  color: viewData.statusStyle.foregroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewData.statusStyle.label,
                      style: AppTextStyles.h1.copyWith(
                        color: viewData.statusStyle.foregroundColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      viewData.subtitle,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceCtaCard extends StatelessWidget {
  const _AttendanceCtaCard({required this.viewData, required this.onPressed});

  final EmployeeHomeStatusViewData viewData;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isClockIn = viewData.cta == EmployeeHomeCta.clockIn;

    return Material(
      color: isClockIn ? AppColors.success : AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(
                isClockIn ? Icons.camera_alt_rounded : Icons.logout_rounded,
                color: AppColors.surface,
                size: 42,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewData.ctaLabel!,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.surface,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      isClockIn
                          ? 'Ambil selfie & catat lokasi'
                          : 'Selesaikan presensi hari ini',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.surface,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.viewData});

  final EmployeeHomeStatusViewData viewData;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Hari Ini',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: 'Jam Masuk',
                  value: viewData.clockInLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeTile(
                  label: 'Jam Pulang',
                  value: viewData.clockOutLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Lokasi',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            viewData.locationLabel,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvasNeutral,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ClockOutConfirmationSheet extends ConsumerWidget {
  const _ClockOutConfirmationSheet({
    required this.attendance,
    required this.previewClockOutTime,
    required this.onCancel,
    required this.onConfirm,
  });

  final AttendanceModel attendance;
  final DateTime previewClockOutTime;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(clockOutControllerProvider);
    final reason = attendance.outsideReason?.trim();
    final hasReason = reason != null && reason.isNotEmpty;
    final isOutside = attendance.isOutside;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isOutside
                              ? AppColors.warningLight
                              : AppColors.softBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOutside
                              ? Icons.pending_actions_rounded
                              : Icons.verified_rounded,
                          color: isOutside
                              ? AppColors.warningDark
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Konfirmasi Absen Pulang',
                              style: AppTextStyles.h2.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              isOutside
                                  ? 'Presensi hari ini tercatat dari luar area kantor. Setelah dikonfirmasi, data akan dikirim untuk validasi admin.'
                                  : 'Periksa kembali ringkasan presensi hari ini sebelum mengakhiri sesi kerja.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ringkasan Presensi',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        AttendanceInfoRow(
                          icon: Icons.login_rounded,
                          label: 'Jam Masuk',
                          value: AppDateTimeFormatter.time(
                            attendance.clockInTime,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AttendanceInfoRow(
                          icon: Icons.logout_rounded,
                          label: 'Jam Pulang',
                          value: AppDateTimeFormatter.time(previewClockOutTime),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AttendanceInfoRow(
                          icon: isOutside
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_outline_rounded,
                          label: 'Status Akhir',
                          value: isOutside ? 'Menunggu Validasi' : 'Selesai',
                          valueColor: isOutside
                              ? AppColors.warningDark
                              : AppColors.success,
                        ),
                        if (hasReason) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ClockOutReasonRow(reason: reason),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ClockOutActions(
                    isSubmitting: submitState.isSubmitting,
                    onCancel: onCancel,
                    onConfirm: onConfirm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockOutReasonRow extends StatelessWidget {
  const _ClockOutReasonRow({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alasan',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                reason,
                style: AppTextStyles.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClockOutActions extends StatelessWidget {
  const _ClockOutActions({
    required this.isSubmitting,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isSubmitting;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final cancelButton = AppButton(
          label: 'Batal',
          onPressed: isSubmitting ? null : onCancel,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.medium,
        );
        final confirmButton = AppButton(
          label: isSubmitting ? 'Menyimpan...' : 'Konfirmasi',
          icon: Icons.check_rounded,
          onPressed: isSubmitting
              ? null
              : () {
                  onConfirm();
                },
          size: AppButtonSize.medium,
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              confirmButton,
              const SizedBox(height: AppSpacing.sm),
              cancelButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: confirmButton),
          ],
        );
      },
    );
  }
}
