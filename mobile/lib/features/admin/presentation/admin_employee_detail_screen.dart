import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/enums/admin_attendance_status_filter.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_date_time_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/profile_avatar_view.dart';
import 'widgets/admin_employee_attendance_card.dart';
import 'widgets/admin_filter_dropdown.dart';
import 'widgets/admin_user_status_badge.dart';
import '../providers/admin_providers.dart';

class AdminEmployeeDetailScreen extends ConsumerStatefulWidget {
  const AdminEmployeeDetailScreen({required this.employeeId, super.key});

  final String employeeId;

  @override
  ConsumerState<AdminEmployeeDetailScreen> createState() =>
      _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState
    extends ConsumerState<AdminEmployeeDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminAttendanceHistoryProvider.notifier)
          .loadInitial(widget.employeeId);
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
      ref.read(adminAttendanceHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(
      adminEmployeeDetailProvider(widget.employeeId),
    );
    final months = ref.watch(
      adminEmployeeAttendanceHistoryMonthsProvider(widget.employeeId),
    );
    final historyState = ref.watch(adminAttendanceHistoryProvider);
    final isCurrentHistory = historyState.employeeId == widget.employeeId;

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
          title: Text('Detail Karyawan', style: AppTextStyles.h2),
        ),
        body: SafeArea(
          child: employeeAsync.when(
            loading: () =>
                const LoadingState(message: 'Memuat detail karyawan...'),
            error: (error, _) => EmptyState(
              icon: Icons.person_search_rounded,
              title: error is ApiException && error.statusCode == 404
                  ? 'Karyawan Tidak Ditemukan'
                  : 'Detail Karyawan Tidak Tersedia',
              message: error is ApiException
                  ? adminReadErrorMessage(error)
                  : 'Data karyawan gagal dimuat. Silakan coba lagi',
              action: AppButton(
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.secondary,
                onPressed: () => ref.invalidate(
                  adminEmployeeDetailProvider(widget.employeeId),
                ),
              ),
            ),
            data: (employee) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(adminEmployeeDetailProvider(widget.employeeId));
                await ref
                    .read(adminAttendanceHistoryProvider.notifier)
                    .refresh();
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EmployeeProfileSummary(employee: employee),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Riwayat Presensi',
                      style: AppTextStyles.h3.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MonthFilter(
                      months: months,
                      activeMonth: isCurrentHistory
                          ? historyState.selectedMonth
                          : months.first,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(adminAttendanceHistoryProvider.notifier)
                              .setMonth(value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusFilterDropdown(
                      value: isCurrentHistory
                          ? historyState.filter
                          : AdminAttendanceStatusFilter.all,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(adminAttendanceHistoryProvider.notifier)
                              .setFilter(value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!isCurrentHistory || historyState.isLoading)
                      const LoadingState(message: 'Memuat riwayat presensi...')
                    else if (historyState.errorMessage != null &&
                        historyState.records.isEmpty)
                      EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'Riwayat Tidak Tersedia',
                        message: historyState.errorMessage!,
                        action: AppButton(
                          label: 'Coba Lagi',
                          icon: Icons.refresh_rounded,
                          size: AppButtonSize.medium,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => ref
                              .read(adminAttendanceHistoryProvider.notifier)
                              .refresh(),
                        ),
                      )
                    else if (historyState.records.isEmpty)
                      const EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'Riwayat Kosong',
                        message:
                            'Tidak ada data presensi pada periode yang dipilih',
                      )
                    else ...[
                      ...historyState.records.map((attendance) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AdminEmployeeAttendanceCard(
                            attendance: attendance,
                            officeName: attendance.officeName ?? '-',
                            onTap: () {
                              context.push(
                                RouteNames.adminAttendanceDetailPath(
                                  attendance.id,
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      if (historyState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: LoadingState(
                            message: 'Memuat data berikutnya...',
                          ),
                        ),
                      if (historyState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: AppButton(
                            label: 'Coba Muat Lagi',
                            icon: Icons.refresh_rounded,
                            size: AppButtonSize.medium,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => ref
                                .read(adminAttendanceHistoryProvider.notifier)
                                .loadMore(),
                          ),
                        ),
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

    context.go(RouteNames.adminEmployees);
  }
}

class _EmployeeProfileSummary extends StatelessWidget {
  const _EmployeeProfileSummary({required this.employee});

  final UserModel employee;

  @override
  Widget build(BuildContext context) {
    final jobTitle = employee.jabatan?.trim().isNotEmpty == true
        ? employee.jabatan!
        : 'Jabatan belum tersedia';

    return AppCard(
      backgroundColor: AppColors.softBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatarView(
            name: employee.name,
            photoPath: employee.photoUrl ?? employee.photoId,
            size: 76,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  jobTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  employee.email,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(
                      icon: Icons.badge_outlined,
                      label: _roleLabel(employee.role),
                    ),
                    AdminUserStatusBadge(isActive: employee.isActive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.employee => 'Karyawan',
      UserRole.admin => 'Admin',
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return AdminFilterDropdown<DateTime>(
      value: activeMonth,
      leadingIcon: Icons.calendar_month_outlined,
      items: months.map((month) {
        return DropdownMenuItem<DateTime>(
          value: month,
          child: Text(
            AppDateTimeFormatter.monthYear(month),
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({required this.value, required this.onChanged});

  final AdminAttendanceStatusFilter value;
  final ValueChanged<AdminAttendanceStatusFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      AdminAttendanceStatusFilter.all,
      AdminAttendanceStatusFilter.checkedIn,
      AdminAttendanceStatusFilter.pending,
      AdminAttendanceStatusFilter.valid,
      AdminAttendanceStatusFilter.rejected,
      AdminAttendanceStatusFilter.sick,
      AdminAttendanceStatusFilter.leave,
      AdminAttendanceStatusFilter.holiday,
    ];

    return AdminFilterDropdown<AdminAttendanceStatusFilter>(
      value: value,
      leadingIcon: Icons.filter_alt_outlined,
      items: filters.map((filter) {
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
