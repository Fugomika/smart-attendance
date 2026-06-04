import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/enums/admin_attendance_status_filter.dart';
import '../../../core/utils/app_date_time_formatter.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/profile_avatar_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_controller.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final profile = ref.watch(profileControllerProvider);
    final selectedDate = ref.watch(adminDashboardSelectedDateProvider);
    final summaryAsync = ref.watch(adminSummaryProvider);
    final displayName = profile?.name ?? currentUser?.name ?? 'Admin';
    final displayPhotoPath = profile?.photoPath ?? currentUser?.photoId;

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.primary,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  name: displayName,
                  photoPath: displayPhotoPath,
                ),
                const SizedBox(height: AppSpacing.md),
                _DateFilterButton(
                  selectedDate: selectedDate,
                  onPressed: () => _pickDate(context, ref, selectedDate),
                ),
                const SizedBox(height: AppSpacing.lg),
                summaryAsync.when(
                  data: (summary) {
                    final needsAttention =
                        summary.pending + summary.absent + summary.others;
                    final cards = [
                      _AdminSummaryCardData(
                        label: 'Hadir',
                        value: summary.present,
                        caption: 'Presensi valid',
                        foregroundColor: AppColors.success,
                        backgroundColor: const Color(0xFFF4FBF7),
                        borderColor: const Color(0xFFCDEEDB),
                        icon: Icons.check_circle_rounded,
                      ),
                      _AdminSummaryCardData(
                        label: 'Pending',
                        value: summary.pending,
                        caption: 'Check-in / validasi',
                        foregroundColor: AppColors.warningDark,
                        backgroundColor: const Color(0xFFFFF8EA),
                        borderColor: AppColors.warningLight,
                        icon: Icons.pending_actions_rounded,
                        isHighlighted: true,
                        onTap: () =>
                            _openPendingReport(context, ref, selectedDate),
                      ),
                      _AdminSummaryCardData(
                        label: 'Tidak Hadir',
                        value: summary.absent,
                        caption: 'Belum ada record',
                        foregroundColor: AppColors.danger,
                        backgroundColor: const Color(0xFFFFF5F5),
                        borderColor: const Color(0xFFFFC7C7),
                        icon: Icons.person_off_rounded,
                      ),
                      _AdminSummaryCardData(
                        label: 'Lainnya',
                        value: summary.others,
                        caption: 'Izin, sakit, libur',
                        foregroundColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF4F6FF),
                        borderColor: const Color(0xFFDCE3FF),
                        icon: Icons.more_horiz_rounded,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TotalSummaryCard(
                          total: summary.total,
                          needsAttention: needsAttention,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Ringkasan Presensi',
                          style: AppTextStyles.h3.copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final spacing = AppSpacing.md;
                            final itemWidth =
                                (constraints.maxWidth - spacing) / 2;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                for (final card in cards)
                                  SizedBox(
                                    width: itemWidth,
                                    child: _SummaryStatCard(data: card),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: LoadingState(
                      message: 'Memuat rekap presensi admin...',
                    ),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(
                      title: 'Rekap belum tersedia',
                      message:
                          'Data dashboard admin belum bisa ditampilkan untuk tanggal ini.',
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      fieldHintText: 'dd/mm/yyyy',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    ref.read(adminDashboardSelectedDateProvider.notifier).setDate(pickedDate);
  }

  void _openPendingReport(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    ref
        .read(adminAttendanceReportSelectedDateProvider.notifier)
        .setDate(selectedDate);
    ref
        .read(adminAttendanceReportStatusFilterProvider.notifier)
        .setFilter(AdminAttendanceStatusFilter.pending);
    ref.read(adminAttendanceReportSearchQueryProvider.notifier).setQuery('');
    context.go(RouteNames.adminReports);
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.name, required this.photoPath});

  final String name;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.surface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pantau presensi karyawan hari ini.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.86),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Hi, $name',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ProfileAvatarView(
            name: name,
            photoPath: photoPath,
            size: 48,
            textStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.selectedDate,
    required this.onPressed,
  });

  final DateTime selectedDate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final prefix = _isToday(selectedDate) ? 'Hari ini' : 'Tanggal';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prefix,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      AppDateTimeFormatter.dateLong(selectedDate),
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}

class _TotalSummaryCard extends StatelessWidget {
  const _TotalSummaryCard({required this.total, required this.needsAttention});

  final int total;
  final int needsAttention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Karyawan Aktif',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;

              final totalValue = Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$total',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'orang',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    totalValue,
                    const SizedBox(height: AppSpacing.sm),
                    _AttentionPill(value: needsAttention),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: totalValue),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _AttentionPill(value: needsAttention),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttentionPill extends StatelessWidget {
  const _AttentionPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final hasAttention = value > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: hasAttention
            ? AppColors.warningLight.withValues(alpha: 0.45)
            : const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: hasAttention
              ? AppColors.warningLight
              : const Color(0xFFCDEEDB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasAttention ? Icons.priority_high_rounded : Icons.check_rounded,
            size: 16,
            color: hasAttention ? AppColors.warningDark : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            hasAttention ? '$value perlu dicek' : 'Aman',
            style: AppTextStyles.caption.copyWith(
              color: hasAttention ? AppColors.warningDark : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.data});

  final _AdminSummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 152),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: data.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: data.isHighlighted
                    ? data.foregroundColor
                    : data.borderColor,
                width: data.isHighlighted ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: data.foregroundColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(
                          color: data.foregroundColor.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        data.icon,
                        color: data.foregroundColor,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.value}',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  data.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: data.foregroundColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.caption,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSummaryCardData {
  const _AdminSummaryCardData({
    required this.label,
    required this.value,
    required this.caption,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    this.isHighlighted = false,
    this.onTap,
  });

  final String label;
  final int value;
  final String caption;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final bool isHighlighted;
  final VoidCallback? onTap;
}
