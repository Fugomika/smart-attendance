import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_time_formatter.dart';
import '../../../../shared/widgets/app_system_overlay.dart';
import '../../../../shared/widgets/attendance_summary_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/employee_attendance_history_providers.dart';

class EmployeeAttendanceHistoryScreen extends ConsumerWidget {
  const EmployeeAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(employeeAttendanceHistoryMonthsProvider);
    final selectedMonth = ref.watch(employeeAttendanceSelectedMonthProvider);
    final activeMonth = selectedMonth ?? (months.isEmpty ? null : months.first);
    final histories = ref.watch(employeeFilteredAttendanceHistoryProvider);
    final selectedMonthController = ref.read(
      employeeAttendanceSelectedMonthProvider.notifier,
    );

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.background,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: months.isEmpty
              ? const EmptyState(
                  icon: Icons.work_history_rounded,
                  title: 'Belum Ada Riwayat',
                  message: 'Data presensi kamu akan muncul di sini.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Absensi', style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Lihat ringkasan presensi berdasarkan bulan.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _MonthFilter(
                        months: months,
                        activeMonth: activeMonth,
                        onChanged: (value) {
                          selectedMonthController.setMonth(value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (histories.isEmpty)
                        const EmptyState(
                          icon: Icons.event_busy_rounded,
                          title: 'Riwayat Kosong',
                          message:
                              'Tidak ada data presensi pada bulan yang dipilih.',
                        )
                      else
                        ...histories.map((attendance) {
                          final office = ref.watch(
                            attendanceOfficeProvider(attendance.officeId),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: AttendanceSummaryCard(
                              attendance: attendance,
                              officeName: office?.name ?? '-',
                              onTap: () {
                                context.go(
                                  RouteNames.employeeAttendanceDetailPath(
                                    attendance.id,
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MonthFilter extends StatelessWidget {
  const _MonthFilter({
    required this.months,
    required this.activeMonth,
    required this.onChanged,
  });

  final List<DateTime> months;
  final DateTime? activeMonth;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<DateTime>(
            value: activeMonth,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            items: months.map((month) {
              return DropdownMenuItem<DateTime>(
                value: month,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppDateTimeFormatter.monthYear(month),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
