import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({required this.currentIndex, super.key});

  final int currentIndex;

  static const _routes = [
    RouteNames.adminDashboard,
    RouteNames.adminEmployees,
    RouteNames.adminReports,
    RouteNames.adminProfile,
  ];

  static const _items = [
    AppBottomNavItem(
      label: 'Dashboard',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    AppBottomNavItem(
      label: 'Karyawan',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    AppBottomNavItem(
      label: 'Laporan',
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
    ),
    AppBottomNavItem(
      label: 'Profil',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_items[currentIndex].activeIcon, size: 72),
                const SizedBox(height: AppSpacing.lg),
                Text(_items[currentIndex].label, style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Admin ${_items[currentIndex].label} placeholder.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                if (currentIndex == 3) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Logout',
                    variant: AppButtonVariant.danger,
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                      context.go(RouteNames.login);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        items: _items,
        onTap: (index) => context.go(_routes[index]),
      ),
    );
  }
}
