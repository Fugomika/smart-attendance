import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_bottom_nav.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

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
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        items: _items,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
