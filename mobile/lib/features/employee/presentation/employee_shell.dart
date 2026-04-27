import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';

class EmployeeShell extends ConsumerWidget {
  const EmployeeShell({required this.currentIndex, super.key});

  final int currentIndex;

  static const _routes = [
    RouteNames.employeeHome,
    RouteNames.employeeHistory,
    RouteNames.employeeNotifications,
    RouteNames.employeeProfile,
  ];

  static const _items = [
    AppBottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    AppBottomNavItem(
      label: 'Riwayat',
      icon: Icons.work_history_outlined,
      activeIcon: Icons.work_history_rounded,
    ),
    AppBottomNavItem(
      label: 'Notifikasi',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
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
                  'Employee ${_items[currentIndex].label} placeholder.',
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
