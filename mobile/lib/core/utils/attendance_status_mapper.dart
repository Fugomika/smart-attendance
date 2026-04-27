import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../enums/attendance_status.dart';

class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
}

class AttendanceStatusMapper {
  const AttendanceStatusMapper._();

  static StatusStyle fromAttendanceStatus(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.checkedIn => const StatusStyle(
        label: 'Sudah Masuk',
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.softBlue,
        borderColor: AppColors.primary,
      ),
      AttendanceStatus.pending => const StatusStyle(
        label: 'Pending',
        foregroundColor: AppColors.warningDark,
        backgroundColor: AppColors.warningLight,
        borderColor: AppColors.warning,
      ),
      AttendanceStatus.valid => const StatusStyle(
        label: 'Valid',
        foregroundColor: AppColors.success,
        backgroundColor: Color(0xFFDDF3E7),
        borderColor: AppColors.success,
      ),
      AttendanceStatus.rejected => const StatusStyle(
        label: 'Ditolak',
        foregroundColor: AppColors.dangerDark,
        backgroundColor: Color(0xFFF8D6D6),
        borderColor: AppColors.danger,
      ),
      AttendanceStatus.sick => const StatusStyle(
        label: 'Sakit',
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.canvasNeutral,
        borderColor: AppColors.border,
      ),
      AttendanceStatus.leave => const StatusStyle(
        label: 'Cuti',
        foregroundColor: AppColors.warningDark,
        backgroundColor: AppColors.warningLight,
        borderColor: AppColors.warning,
      ),
      AttendanceStatus.holiday => const StatusStyle(
        label: 'Libur',
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.canvasNeutral,
        borderColor: AppColors.border,
      ),
    };
  }

  static const notCheckedIn = StatusStyle(
    label: 'Belum Absen',
    foregroundColor: AppColors.dangerDark,
    backgroundColor: Color(0xFFF8D6D6),
    borderColor: AppColors.danger,
  );
}
