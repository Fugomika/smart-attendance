import 'package:flutter/material.dart';

import '../../app/app_keys.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum _AppSnackBarType { success, error, warning, info }

class AppSnackBar {
  const AppSnackBar._();

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      type: _AppSnackBarType.success,
      icon: Icons.check_circle_outline_rounded,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message,
      type: _AppSnackBarType.error,
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message,
      type: _AppSnackBarType.warning,
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      type: _AppSnackBarType.info,
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }

  static void offline(
    BuildContext context, {
    String message = 'Tidak ada koneksi internet',
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message,
      type: _AppSnackBarType.warning,
      icon: Icons.wifi_off_rounded,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required _AppSnackBarType type,
    required IconData icon,
    required Duration duration,
  }) {
    final messenger =
        AppKeys.scaffoldMessenger.currentState ??
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _backgroundColor(type),
          elevation: 0,
          duration: duration,
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          content: Row(
            children: [
              Icon(icon, color: _foregroundColor(type), size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _foregroundColor(type),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static Color _backgroundColor(_AppSnackBarType type) {
    return switch (type) {
      _AppSnackBarType.success => AppColors.success,
      _AppSnackBarType.error => AppColors.danger,
      _AppSnackBarType.warning => AppColors.warning,
      _AppSnackBarType.info => AppColors.primary,
    };
  }

  static Color _foregroundColor(_AppSnackBarType type) {
    return switch (type) {
      _AppSnackBarType.warning => AppColors.textPrimary,
      _ => AppColors.surface,
    };
  }
}
