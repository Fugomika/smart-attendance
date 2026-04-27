import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/attendance_status_mapper.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.style, super.key});

  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        style.label,
        style: AppTextStyles.bodyMedium.copyWith(color: style.foregroundColor),
      ),
    );
  }
}
