import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, danger, success }

enum AppButtonSize { large, medium, small }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final style = ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      disabledBackgroundColor: AppColors.border,
      disabledForegroundColor: AppColors.textSecondary,
      minimumSize: Size.fromHeight(_height),
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      textStyle: _textStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: colors.border),
      ),
    );

    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: _iconSize),
              const SizedBox(width: AppSpacing.xs),
              Text(label),
            ],
          );

    return ElevatedButton(onPressed: onPressed, style: style, child: child);
  }

  double get _height {
    return switch (size) {
      AppButtonSize.large => 56,
      AppButtonSize.medium => 48,
      AppButtonSize.small => 36,
    };
  }

  double get _radius {
    return switch (size) {
      AppButtonSize.large => AppRadius.large,
      AppButtonSize.medium => AppRadius.medium,
      AppButtonSize.small => AppRadius.small,
    };
  }

  double get _horizontalPadding {
    return switch (size) {
      AppButtonSize.large => AppSpacing.lg,
      AppButtonSize.medium => AppSpacing.md,
      AppButtonSize.small => AppSpacing.sm,
    };
  }

  double get _iconSize => size == AppButtonSize.small ? 16 : 20;

  TextStyle get _textStyle {
    return switch (size) {
      AppButtonSize.large => AppTextStyles.bodyMedium.copyWith(fontSize: 18),
      AppButtonSize.medium => AppTextStyles.bodyMedium,
      AppButtonSize.small => AppTextStyles.caption.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    };
  }

  _ButtonColors get _colors {
    return switch (variant) {
      AppButtonVariant.primary => const _ButtonColors(
        background: AppColors.primary,
        foreground: AppColors.surface,
        border: AppColors.primary,
      ),
      AppButtonVariant.secondary => const _ButtonColors(
        background: AppColors.softBlue,
        foreground: AppColors.primary,
        border: AppColors.softBlue,
      ),
      AppButtonVariant.outline => const _ButtonColors(
        background: Colors.transparent,
        foreground: AppColors.primary,
        border: AppColors.primary,
      ),
      AppButtonVariant.danger => const _ButtonColors(
        background: Color(0xFFF8D6D6),
        foreground: AppColors.dangerDark,
        border: AppColors.danger,
      ),
      AppButtonVariant.success => const _ButtonColors(
        background: AppColors.success,
        foreground: AppColors.surface,
        border: AppColors.success,
      ),
    };
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
