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
import '../../../data/models/attendance_model.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../auth/providers/auth_provider.dart';
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
    final attendance = ref.watch(todayAttendanceProvider);
    final office = ref.watch(todayAttendanceOfficeProvider);
    final effectiveAttendance = _debugAttendancePreview.resolve(
      liveAttendance: attendance,
      date: EmployeeHomeScreen._fallbackAttendanceDate,
      userId: user?.id ?? 'debug-user',
    );
    final attendanceDate =
        effectiveAttendance?.attendanceDate ??
        EmployeeHomeScreen._fallbackAttendanceDate;
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
                  name: user?.name ?? 'Karyawan',
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
                    onPressed: () => _handleCta(context, viewData.cta!),
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

  static void _handleCta(BuildContext context, EmployeeHomeCta cta) {
    if (cta == EmployeeHomeCta.clockIn) {
      context.go(RouteNames.employeeAttendanceLocation);
      return;
    }

    AppSnackBar.info(context, 'Flow absen pulang akan dibuat di Batch 5.');
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
  const _HomeHeader({required this.name, required this.greeting});

  final String name;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialAvatar(name: name),
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

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTextStyles.h3.copyWith(
          color: AppColors.textSecondary,
          fontSize: 21,
        ),
      ),
    );
  }

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
