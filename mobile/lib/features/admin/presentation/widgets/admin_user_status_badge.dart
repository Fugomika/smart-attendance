import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class AdminUserStatusBadge extends StatelessWidget {
  const AdminUserStatusBadge({required this.isActive, super.key});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final label = isActive ? 'Aktif' : 'Nonaktif';
    final foregroundColor = isActive ? AppColors.success : AppColors.danger;
    final backgroundColor = isActive
        ? const Color(0xFFEFFAF3)
        : const Color(0xFFFFF1F1);
    final borderColor = isActive
        ? const Color(0xFFCDEEDB)
        : const Color(0xFFFFC7C7);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
