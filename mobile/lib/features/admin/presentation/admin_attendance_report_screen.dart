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
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_tab_header.dart';
import 'widgets/admin_attendance_report_card.dart';
import 'widgets/admin_filter_dropdown.dart';

class AdminAttendanceReportScreen extends ConsumerStatefulWidget {
  const AdminAttendanceReportScreen({super.key});

  @override
  ConsumerState<AdminAttendanceReportScreen> createState() =>
      _AdminAttendanceReportScreenState();
}

class _AdminAttendanceReportScreenState
    extends ConsumerState<AdminAttendanceReportScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminAttendanceReportProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 320) {
      ref.read(adminAttendanceReportProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(adminAttendanceReportProvider);

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
                            .read(adminAttendanceReportProvider.notifier)
                            .setQuery(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DateFilterButton(
                      date: reportState.selectedDate,
                      onTap: () =>
                          _pickDate(context, ref, reportState.selectedDate),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusFilterDropdown(
                      value: reportState.filter,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        ref
                            .read(adminAttendanceReportProvider.notifier)
                            .setFilter(value);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: reportState.isLoading
                    ? const LoadingState(message: 'Memuat laporan presensi...')
                    : reportState.errorMessage != null &&
                          reportState.records.isEmpty
                    ? EmptyState(
                        icon: Icons.description_outlined,
                        title: 'Laporan Tidak Tersedia',
                        message: reportState.errorMessage!,
                        action: AppButton(
                          label: 'Coba Lagi',
                          icon: Icons.refresh_rounded,
                          size: AppButtonSize.medium,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => ref
                              .read(adminAttendanceReportProvider.notifier)
                              .refresh(),
                        ),
                      )
                    : reportState.records.isEmpty
                    ? _RefreshableReportState(
                        onRefresh: () => ref
                            .read(adminAttendanceReportProvider.notifier)
                            .refresh(),
                        child: _ReportEmptyState(
                          searchQuery: reportState.query,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(adminAttendanceReportProvider.notifier)
                            .refresh(),
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          itemCount:
                              reportState.records.length +
                              (reportState.isLoadingMore ||
                                      reportState.errorMessage != null
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            if (index == reportState.records.length) {
                              if (reportState.isLoadingMore) {
                                return const LoadingState(
                                  message: 'Memuat data berikutnya...',
                                );
                              }
                              return AppButton(
                                label: 'Coba Muat Lagi',
                                icon: Icons.refresh_rounded,
                                size: AppButtonSize.medium,
                                variant: AppButtonVariant.secondary,
                                onPressed: () => ref
                                    .read(
                                      adminAttendanceReportProvider.notifier,
                                    )
                                    .loadMore(),
                              );
                            }

                            final row = reportState.records[index];
                            final attendance = row.attendance;
                            return AdminAttendanceReportCard(
                              row: row,
                              dateLabel: _formatShortDate(row.selectedDate),
                              officeName: attendance?.officeName ?? '-',
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
                        ),
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

    ref.read(adminAttendanceReportProvider.notifier).setDate(pickedDate);
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

class _RefreshableReportState extends StatelessWidget {
  const _RefreshableReportState({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: constraints.maxHeight, child: child)],
          ),
        );
      },
    );
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
          ? 'Gunakan nama atau email lain'
          : 'Data laporan presensi akan muncul di sini',
      icon: hasQuery ? Icons.search_off_rounded : Icons.description_outlined,
    );
  }
}
