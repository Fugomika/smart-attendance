import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/attendance_status_mapper.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/profile_avatar_view.dart';
import '../../../../shared/widgets/status_badge.dart';

class AdminAttendanceReportCard extends StatelessWidget {
  const AdminAttendanceReportCard({
    required this.row,
    required this.dateLabel,
    required this.officeName,
    this.onTap,
    super.key,
  });

  final AdminAttendanceReportRow row;
  final String dateLabel;
  final String officeName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final attendance = row.attendance;
    final statusStyle = attendance == null
        ? AttendanceStatusMapper.notCheckedIn
        : AttendanceStatusMapper.fromAttendanceStatus(attendance.status);
    final jobTitle = row.user.jabatan?.trim().isNotEmpty == true
        ? row.user.jabatan!
        : 'Jabatan belum tersedia';

    return AppCard(
      onTap: attendance == null ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatarView(
            name: row.user.name,
            photoPath: row.user.photoId,
            size: 52,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.user.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            jobTitle,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(style: statusStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  dateLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (attendance != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    label: 'Masuk',
                    value: _formatTime(attendance.clockInTime),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _InfoRow(
                    label: 'Pulang',
                    value: _formatTime(attendance.clockOutTime),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kantor',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              officeName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
