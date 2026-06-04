import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/profile_avatar_view.dart';
import 'package:go_router/go_router.dart';
import 'widgets/admin_tab_header.dart';
import 'widgets/admin_user_status_badge.dart';
import '../providers/admin_providers.dart';

class AdminEmployeeListScreen extends ConsumerWidget {
  const AdminEmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(adminEmployeeStatusFilterProvider);
    final searchQuery = ref.watch(adminEmployeeSearchQueryProvider);
    final employees = ref.watch(filteredEmployeeListProvider);

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.primary,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AdminTabHeader(title: 'Karyawan'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: _EmployeeStatusTabs(
                  selectedFilter: selectedFilter,
                  onSelected: (filter) {
                    ref
                        .read(adminEmployeeStatusFilterProvider.notifier)
                        .setFilter(filter);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: AppSearchField(
                  hintText: 'Cari nama atau email',
                  onChanged: (value) {
                    ref
                        .read(adminEmployeeSearchQueryProvider.notifier)
                        .setQuery(value);
                  },
                ),
              ),
              Expanded(
                child: employees.isEmpty
                    ? _EmployeeEmptyState(searchQuery: searchQuery)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: employees.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return _AdminEmployeeCard(
                            employee: employee,
                            onTap: () {
                              context.push(
                                RouteNames.adminEmployeeDetailPath(employee.id),
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
}

class _EmployeeStatusTabs extends StatelessWidget {
  const _EmployeeStatusTabs({
    required this.selectedFilter,
    required this.onSelected,
  });

  final AdminEmployeeStatusFilter selectedFilter;
  final ValueChanged<AdminEmployeeStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final filter in AdminEmployeeStatusFilter.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: filter == AdminEmployeeStatusFilter.values.last
                    ? 0
                    : AppSpacing.sm,
              ),
              child: _EmployeeStatusTabButton(
                label: filter.label,
                isSelected: selectedFilter == filter,
                onTap: () => onSelected(filter),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmployeeStatusTabButton extends StatelessWidget {
  const _EmployeeStatusTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softBlue : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminEmployeeCard extends StatelessWidget {
  const _AdminEmployeeCard({required this.employee, required this.onTap});

  final UserModel employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatarView(
            name: employee.name,
            photoPath: employee.photoId,
            size: 56,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final jobTitle = employee.jabatan?.trim().isNotEmpty == true
                    ? employee.jabatan!
                    : 'Jabatan belum tersedia';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: Text(
                              employee.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        AdminUserStatusBadge(isActive: employee.isActive),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      jobTitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      employee.email,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeEmptyState extends StatelessWidget {
  const _EmployeeEmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchQuery.trim().isNotEmpty;

    return EmptyState(
      title: hasQuery ? 'Karyawan tidak ditemukan' : 'Belum ada data karyawan',
      message: hasQuery
          ? 'Gunakan nama atau email lain.'
          : 'Data karyawan akan muncul di sini setelah tersedia.',
      icon: hasQuery ? Icons.search_off_rounded : Icons.groups_rounded,
    );
  }
}
