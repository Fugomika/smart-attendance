import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_time_formatter.dart';
import '../../../../core/utils/attendance_status_mapper.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../shared/widgets/app_card.dart';

class AdminEmployeeAttendanceCard extends StatelessWidget {
  const AdminEmployeeAttendanceCard({
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AttendanceThumbnail(selfieUrl: attendance.selfieUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _formatShortDate(attendance.attendanceDate),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CompactStatusBadge(style: statusStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _TimeItem(
                  label: 'Masuk',
                  value: AppDateTimeFormatter.time(attendance.clockInTime),
                ),
                const SizedBox(height: AppSpacing.xs),
                _TimeItem(
                  label: 'Pulang',
                  value: AppDateTimeFormatter.time(attendance.clockOutTime),
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
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      attendance.isOutside
                          ? Icons.pin_drop_outlined
                          : Icons.location_on_rounded,
                      color: AppColors.success.withValues(alpha: 0.82),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}

class _AttendanceThumbnail extends StatelessWidget {
  const _AttendanceThumbnail({required this.selfieUrl});

  final String? selfieUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = selfieUrl != null && selfieUrl!.trim().isNotEmpty;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.canvasNeutral,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasPhoto
          ? Image.network(
              selfieUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ThumbnailFallback(),
            )
          : const _ThumbnailFallback(),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.hide_image_outlined,
      color: AppColors.textMuted,
      size: 20,
    );
  }
}

class _CompactStatusBadge extends StatelessWidget {
  const _CompactStatusBadge({required this.style});

  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        style.label,
        style: AppTextStyles.caption.copyWith(
          color: style.foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  const _TimeItem({required this.label, required this.value});

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
