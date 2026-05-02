import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/enums/attendance_status.dart';
import '../../../core/utils/attendance_status_mapper.dart';
import '../../../data/models/attendance_model.dart';

enum EmployeeHomeCta { clockIn, clockOut }

class EmployeeHomeStatusViewData {
  const EmployeeHomeStatusViewData({
    required this.statusStyle,
    required this.subtitle,
    required this.clockInLabel,
    required this.clockOutLabel,
    required this.locationLabel,
    this.cta,
    this.ctaLabel,
  });

  final StatusStyle statusStyle;
  final String subtitle;
  final String clockInLabel;
  final String clockOutLabel;
  final String locationLabel;
  final EmployeeHomeCta? cta;
  final String? ctaLabel;

  bool get hasCta => cta != null && ctaLabel != null;
}

class EmployeeHomeStatusMapper {
  const EmployeeHomeStatusMapper._();

  static EmployeeHomeStatusViewData fromAttendance(
    AttendanceModel? attendance, {
    String locationLabel = '-',
  }) {
    if (attendance == null) {
      return const EmployeeHomeStatusViewData(
        statusStyle: StatusStyle(
          label: 'Belum Absen',
          foregroundColor: AppColors.warningDark,
          backgroundColor: AppColors.warningLight,
          borderColor: AppColors.warning,
        ),
        subtitle: 'Jangan lupa absen sebelum bekerja ya!',
        clockInLabel: '-',
        clockOutLabel: '-',
        locationLabel: '-',
        cta: EmployeeHomeCta.clockIn,
        ctaLabel: 'Absen Sekarang',
      );
    }

    final clockInLabel = _formatTime(attendance.clockInTime);
    final clockOutLabel = _formatTime(attendance.clockOutTime);
    final resolvedLocationLabel = locationLabel.trim().isEmpty
        ? '-'
        : locationLabel.trim();

    return switch (attendance.status) {
      AttendanceStatus.checkedIn =>
        attendance.isOutside
            ? EmployeeHomeStatusViewData(
                statusStyle: const StatusStyle(
                  label: 'Di Luar Kantor',
                  foregroundColor: AppColors.warningDark,
                  backgroundColor: AppColors.warningLight,
                  borderColor: AppColors.warning,
                ),
                subtitle: 'Presensi masuk tercatat dari luar area kantor.',
                clockInLabel: clockInLabel,
                clockOutLabel: '-',
                locationLabel: resolvedLocationLabel,
                cta: EmployeeHomeCta.clockOut,
                ctaLabel: 'Absen Pulang',
              )
            : EmployeeHomeStatusViewData(
                statusStyle: const StatusStyle(
                  label: 'Sudah Masuk',
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.softBlue,
                  borderColor: AppColors.primary,
                ),
                subtitle: 'Jangan lupa absen pulang nanti ya!',
                clockInLabel: clockInLabel,
                clockOutLabel: '-',
                locationLabel: resolvedLocationLabel,
                cta: EmployeeHomeCta.clockOut,
                ctaLabel: 'Absen Pulang',
              ),
      AttendanceStatus.pending => EmployeeHomeStatusViewData(
        statusStyle: const StatusStyle(
          label: 'Menunggu Validasi',
          foregroundColor: AppColors.warningDark,
          backgroundColor: AppColors.warningLight,
          borderColor: AppColors.warning,
        ),
        subtitle: 'Presensi Anda sedang ditinjau admin.',
        clockInLabel: clockInLabel,
        clockOutLabel: clockOutLabel,
        locationLabel: resolvedLocationLabel,
      ),
      AttendanceStatus.valid => EmployeeHomeStatusViewData(
        statusStyle: const StatusStyle(
          label: 'Selesai',
          foregroundColor: AppColors.success,
          backgroundColor: Color(0xFFDDF3E7),
          borderColor: AppColors.success,
        ),
        subtitle: 'Terima kasih, kerja hari ini selesai.',
        clockInLabel: clockInLabel,
        clockOutLabel: clockOutLabel,
        locationLabel: resolvedLocationLabel,
      ),
      AttendanceStatus.rejected => EmployeeHomeStatusViewData(
        statusStyle: const StatusStyle(
          label: 'Ditolak',
          foregroundColor: AppColors.dangerDark,
          backgroundColor: Color(0xFFF8D6D6),
          borderColor: AppColors.danger,
        ),
        subtitle: 'Silakan hubungi admin untuk informasi lebih lanjut.',
        clockInLabel: clockInLabel,
        clockOutLabel: clockOutLabel,
        locationLabel: resolvedLocationLabel,
      ),
      AttendanceStatus.sick => const EmployeeHomeStatusViewData(
        statusStyle: StatusStyle(
          label: 'Sakit',
          foregroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.canvasNeutral,
          borderColor: AppColors.border,
        ),
        subtitle: 'Tidak ada presensi hari ini.',
        clockInLabel: '-',
        clockOutLabel: '-',
        locationLabel: '-',
      ),
      AttendanceStatus.leave => const EmployeeHomeStatusViewData(
        statusStyle: StatusStyle(
          label: 'Cuti',
          foregroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.canvasNeutral,
          borderColor: AppColors.border,
        ),
        subtitle: 'Tidak ada presensi hari ini.',
        clockInLabel: '-',
        clockOutLabel: '-',
        locationLabel: '-',
      ),
      AttendanceStatus.holiday => const EmployeeHomeStatusViewData(
        statusStyle: StatusStyle(
          label: 'Hari Libur',
          foregroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.canvasNeutral,
          borderColor: AppColors.border,
        ),
        subtitle: 'Tidak ada presensi hari ini.',
        clockInLabel: '-',
        clockOutLabel: '-',
        locationLabel: '-',
      ),
    };
  }

  static String _formatTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return DateFormat('HH:mm').format(value);
  }
}
