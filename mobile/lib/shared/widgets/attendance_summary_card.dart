import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/app_date_time_formatter.dart';
import '../../core/utils/attendance_status_mapper.dart';
import '../../data/models/attendance_model.dart';
import 'app_card.dart';
import 'status_badge.dart';

class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({
    required this.attendance,
    required this.officeName,
    this.onTap,
    super.key,
  });

  final AttendanceModel attendance;
  final String officeName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = AttendanceStatusMapper.fromAttendanceStatus(
      attendance.status,
    );

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  AppDateTimeFormatter.dateLong(attendance.attendanceDate),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(style: statusStyle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _TimeSummaryItem(
                  label: 'Masuk',
                  value: AppDateTimeFormatter.time(attendance.clockInTime),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TimeSummaryItem(
                  label: 'Pulang',
                  value: AppDateTimeFormatter.time(attendance.clockOutTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  officeName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeSummaryItem extends StatelessWidget {
  const _TimeSummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
