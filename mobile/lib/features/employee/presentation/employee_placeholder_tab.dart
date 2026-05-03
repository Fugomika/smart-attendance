import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_system_overlay.dart';

class EmployeePlaceholderTab extends StatelessWidget {
  const EmployeePlaceholderTab({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.onLogout,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.background,
      navigationBarColor: AppColors.surface,
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 72, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title, style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Employee $title placeholder.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  if (onAction != null && actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: actionLabel!,
                      variant: AppButtonVariant.secondary,
                      icon: Icons.admin_panel_settings_rounded,
                      onPressed: onAction,
                    ),
                  ],
                  if (onLogout != null) ...[
                    SizedBox(
                      height: onAction != null && actionLabel != null
                          ? AppSpacing.md
                          : AppSpacing.xl,
                    ),
                    AppButton(
                      label: 'Logout',
                      variant: AppButtonVariant.danger,
                      onPressed: onLogout,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
