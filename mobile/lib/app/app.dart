import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_keys.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../shared/widgets/app_system_overlay.dart';

class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppKeys.scaffoldMessenger,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        return AppSystemOverlay.darkIcons(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
