import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class AdminPlaceholderTab extends StatelessWidget {
  const AdminPlaceholderTab({
    required this.title,
    required this.icon,
    this.onLogout,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Admin $title placeholder.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              if (onLogout != null) ...[
                const SizedBox(height: AppSpacing.xl),
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
    );
  }
}
