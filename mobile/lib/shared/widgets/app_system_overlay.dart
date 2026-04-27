import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';

class AppSystemOverlay extends StatelessWidget {
  const AppSystemOverlay({required this.child, required this.style, super.key});

  AppSystemOverlay.darkIcons({
    required Widget child,
    Color statusBarColor = AppColors.surface,
    Color navigationBarColor = AppColors.surface,
    Key? key,
  }) : this(
         key: key,
         style: SystemUiOverlayStyle(
           statusBarColor: statusBarColor,
           statusBarIconBrightness: Brightness.dark,
           statusBarBrightness: Brightness.light,
           systemNavigationBarColor: navigationBarColor,
           systemNavigationBarIconBrightness: Brightness.dark,
         ),
         child: child,
       );

  AppSystemOverlay.lightIcons({
    required Widget child,
    Color statusBarColor = Colors.transparent,
    Color navigationBarColor = AppColors.surface,
    Key? key,
  }) : this(
         key: key,
         style: SystemUiOverlayStyle(
           statusBarColor: statusBarColor,
           statusBarIconBrightness: Brightness.light,
           statusBarBrightness: Brightness.dark,
           systemNavigationBarColor: navigationBarColor,
           systemNavigationBarIconBrightness: Brightness.dark,
         ),
         child: child,
       );

  final Widget child;
  final SystemUiOverlayStyle style;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(value: style, child: child);
  }
}
