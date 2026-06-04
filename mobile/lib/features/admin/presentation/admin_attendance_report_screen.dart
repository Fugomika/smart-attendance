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
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_tab_header.dart';
import 'widgets/admin_attendance_report_card.dart';
import 'widgets/admin_filter_dropdown.dart';

class AdminAttendanceReportScreen extends ConsumerWidget {
  const AdminAttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(adminAttendanceReportSelectedDateProvider);
    final searchQuery = ref.watch(adminAttendanceReportSearchQueryProvider);
    final statusFilter = ref.watch(adminAttendanceReportStatusFilterProvider);
    final rowsAsync = ref.watch(adminAttendanceReportRowsProvider);

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.primary,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AdminTabHeader(title: 'Laporan Presensi'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSearchField(
                      hintText: 'Cari nama atau email',
                      onChanged: (value) {
                        ref
                            .read(
                              adminAttendanceReportSearchQueryProvider.notifier,
                            )
                            .setQuery(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DateFilterButton(
                      date: selectedDate,
                      onTap: () => _pickDate(context, ref, selectedDate),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusFilterDropdown(
                      value: statusFilter,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        ref
                            .read(
                              adminAttendanceReportStatusFilterProvider
                                  .notifier,
                            )
                            .setFilter(value);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: rowsAsync.when(
                  loading: () =>
                      const LoadingState(message: 'Memuat laporan presensi...'),
                  error: (_, _) => const EmptyState(
                    icon: Icons.description_outlined,
                    title: 'Laporan Tidak Tersedia',
                    message: 'Data laporan belum bisa ditampilkan.',
                  ),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return _ReportEmptyState(searchQuery: searchQuery);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final attendance = row.attendance;
                        final officeName = attendance == null
                            ? '-'
                            : ref
                                      .watch(
                                        adminAttendanceOfficeProvider(
                                          attendance.officeId,
                                        ),
                                      )
                                      ?.name ??
                                  '-';

                        return AdminAttendanceReportCard(
                          row: row,
                          dateLabel: _formatShortDate(row.selectedDate),
                          officeName: officeName,
                          onTap: attendance == null
                              ? null
                              : () {
                                  context.push(
                                    RouteNames.adminAttendanceDetailPath(
                                      attendance.id,
                                    ),
                                  );
                                },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );

    if (pickedDate == null) {
      return;
    }

    ref
        .read(adminAttendanceReportSelectedDateProvider.notifier)
        .setDate(pickedDate);
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
}

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({required this.value, required this.onChanged});

  final AdminAttendanceStatusFilter value;
  final ValueChanged<AdminAttendanceStatusFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AdminFilterDropdown<AdminAttendanceStatusFilter>(
      value: value,
      leadingIcon: Icons.filter_alt_outlined,
      items: AdminAttendanceStatusFilter.values.map((filter) {
        return DropdownMenuItem<AdminAttendanceStatusFilter>(
          value: filter,
          child: Text(
            filter.label,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppDateTimeFormatter.dateLong(date),
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportEmptyState extends StatelessWidget {
  const _ReportEmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchQuery.trim().isNotEmpty;

    return EmptyState(
      title: hasQuery ? 'Laporan tidak ditemukan' : 'Belum ada data laporan',
      message: hasQuery
          ? 'Gunakan nama atau email lain.'
          : 'Data laporan presensi akan muncul di sini.',
      icon: hasQuery ? Icons.search_off_rounded : Icons.description_outlined,
    );
  }
}
