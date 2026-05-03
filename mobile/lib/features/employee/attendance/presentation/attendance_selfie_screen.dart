import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/utils/app_snack_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_system_overlay.dart';
import '../models/attendance_location_result.dart';
import '../models/attendance_selfie_result.dart';
import '../models/attendance_selfie_state.dart';
import '../providers/attendance_selfie_controller.dart';
import '../providers/clock_in_controller.dart';

class AttendanceSelfieScreen extends ConsumerStatefulWidget {
  const AttendanceSelfieScreen({this.locationResult, super.key});

  final AttendanceLocationResult? locationResult;

  @override
  ConsumerState<AttendanceSelfieScreen> createState() =>
      _AttendanceSelfieScreenState();
}

class _AttendanceSelfieScreenState
    extends ConsumerState<AttendanceSelfieScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.locationResult == null) {
        return;
      }

      ref.read(attendanceSelfieControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationResult = widget.locationResult;
    final selfieState = ref.watch(attendanceSelfieControllerProvider);
    final clockInState = ref.watch(clockInControllerProvider);
    final selfieController = ref.read(
      attendanceSelfieControllerProvider.notifier,
    );

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.surface,
      navigationBarColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text('Absen Masuk', style: AppTextStyles.h3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(RouteNames.employeeAttendanceLocation),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: locationResult == null
                ? const _MissingLocationResult()
                : _SelfieContent(
                    locationResult: locationResult,
                    state: selfieState,
                    cameraController: selfieController.cameraController,
                    onCapture: () {
                      selfieController.capture();
                    },
                    onRetake: selfieController.retake,
                    onRetry: () {
                      selfieController.retry();
                    },
                    isSubmitting: clockInState.isSubmitting,
                    onContinue: () =>
                        _handleContinue(context, locationResult, selfieState),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue(
    BuildContext context,
    AttendanceLocationResult locationResult,
    AttendanceSelfieState selfieState,
  ) async {
    final selfiePath = selfieState.selfiePath;
    final capturedAt = selfieState.capturedAt;
    if (selfiePath == null || capturedAt == null) {
      AppSnackBar.warning(context, 'Ambil selfie terlebih dahulu.');
      return;
    }

    final result = AttendanceSelfieResult(
      locationResult: locationResult,
      selfiePath: selfiePath,
      capturedAt: capturedAt,
    );

    final attendance = await ref
        .read(clockInControllerProvider.notifier)
        .submit(result);
    if (!mounted) {
      return;
    }

    if (attendance == null) {
      final message =
          ref.read(clockInControllerProvider).message ??
          'Absen masuk gagal disimpan. Coba lagi.';
      AppSnackBar.error(context, message);
      return;
    }

    AppSnackBar.success(context, 'Absen masuk berhasil disimpan.');
    context.go(RouteNames.employeeHome);
  }
}

class _MissingLocationResult extends StatelessWidget {
  const _MissingLocationResult();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_off_rounded,
                color: AppColors.danger,
                size: 36,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Data lokasi belum tersedia', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Silakan ulangi validasi lokasi sebelum mengambil selfie.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        AppButton(
          label: 'Kembali ke Validasi Lokasi',
          icon: Icons.location_searching_rounded,
          onPressed: () => context.go(RouteNames.employeeAttendanceLocation),
        ),
      ],
    );
  }
}

class _SelfieContent extends StatelessWidget {
  const _SelfieContent({
    required this.locationResult,
    required this.state,
    required this.cameraController,
    required this.onCapture,
    required this.onRetake,
    required this.onRetry,
    required this.isSubmitting,
    required this.onContinue,
  });

  final AttendanceLocationResult locationResult;
  final AttendanceSelfieState state;
  final CameraController? cameraController;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final VoidCallback onRetry;
  final bool isSubmitting;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        final cameraHeight = _cameraHeight(constraints.maxHeight, compact);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pastikan wajah terlihat jelas di dalam frame',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: compact ? 18 : 20,
                    height: 1.28,
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                SizedBox(
                  height: cameraHeight,
                  child: _CameraPanel(
                    state: state,
                    cameraController: cameraController,
                    onRetry: onRetry,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _LocationSummaryCard(locationResult: locationResult),
                const SizedBox(height: AppSpacing.md),
                _SelfieActions(
                  state: state,
                  onCapture: onCapture,
                  onRetake: onRetake,
                  isSubmitting: isSubmitting,
                  onContinue: onContinue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _cameraHeight(double availableHeight, bool compact) {
    final reservedHeight = compact ? 230.0 : 260.0;
    final height = availableHeight - reservedHeight;
    return height.clamp(compact ? 300.0 : 340.0, compact ? 390.0 : 450.0);
  }
}

class _CameraPanel extends StatelessWidget {
  const _CameraPanel({
    required this.state,
    required this.cameraController,
    required this.onRetry,
  });

  final AttendanceSelfieState state;
  final CameraController? cameraController;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: ColoredBox(
        color: AppColors.canvasNeutral,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPanelBody(
              state: state,
              cameraController: cameraController,
              onRetry: onRetry,
            ),
            if (state.status == AttendanceSelfieStatus.ready ||
                state.status == AttendanceSelfieStatus.capturing)
              const CustomPaint(painter: _FaceGuidePainter()),
          ],
        ),
      ),
    );
  }
}

class _CameraPanelBody extends StatelessWidget {
  const _CameraPanelBody({
    required this.state,
    required this.cameraController,
    required this.onRetry,
  });

  final AttendanceSelfieState state;
  final CameraController? cameraController;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.hasCapturedPhoto) {
      return Image.file(File(state.selfiePath!), fit: BoxFit.cover);
    }

    final controller = cameraController;
    if ((state.isReady || state.isCapturing) &&
        controller != null &&
        controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      );
    }

    if (state.isInitializing) {
      return _CameraMessage(
        icon: Icons.camera_alt_rounded,
        title: 'Menyiapkan kamera',
        description: state.message ?? 'Mohon tunggu sebentar.',
        showProgress: true,
      );
    }

    return _CameraMessage(
      icon: _errorIcon(state.status),
      title: _errorTitle(state.status),
      description: state.message ?? 'Kamera belum bisa digunakan.',
      actionLabel: 'Coba Lagi',
      onAction: onRetry,
    );
  }

  IconData _errorIcon(AttendanceSelfieStatus status) {
    return switch (status) {
      AttendanceSelfieStatus.permissionDenied => Icons.no_photography_rounded,
      AttendanceSelfieStatus.cameraUnavailable => Icons.videocam_off_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  String _errorTitle(AttendanceSelfieStatus status) {
    return switch (status) {
      AttendanceSelfieStatus.permissionDenied => 'Izin kamera ditolak',
      AttendanceSelfieStatus.cameraUnavailable => 'Kamera depan tidak tersedia',
      _ => 'Kamera bermasalah',
    };
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: AppSpacing.md),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 180,
                child: AppButton(
                  label: actionLabel!,
                  size: AppButtonSize.medium,
                  variant: AppButtonVariant.secondary,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({required this.locationResult});

  final AttendanceLocationResult locationResult;

  @override
  Widget build(BuildContext context) {
    final isOutside = locationResult.isOutside;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LocationIcon(isOutside: isOutside),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locationResult.office.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _LocationStatusPill(isOutside: isOutside),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _CompactMeta(
                      icon: Icons.near_me_rounded,
                      label:
                          '${_formatDistance(locationResult.distanceMeters)} dari kantor',
                    ),
                    if (locationResult.outsideReason != null)
                      const _CompactMeta(
                        icon: Icons.edit_note_rounded,
                        label: 'Alasan tercatat',
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

  static String _formatDistance(double distanceMeters) {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }

    return '${distanceMeters.round()} m';
  }
}

class _LocationIcon extends StatelessWidget {
  const _LocationIcon({required this.isOutside});

  final bool isOutside;

  @override
  Widget build(BuildContext context) {
    final color = isOutside ? AppColors.warning : AppColors.success;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Icon(Icons.location_on_rounded, color: color, size: 24),
    );
  }
}

class _CompactMeta extends StatelessWidget {
  const _CompactMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationStatusPill extends StatelessWidget {
  const _LocationStatusPill({required this.isOutside});

  final bool isOutside;

  @override
  Widget build(BuildContext context) {
    final color = isOutside ? AppColors.warning : AppColors.success;
    final label = isOutside ? 'Luar area' : 'Valid';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelfieActions extends StatelessWidget {
  const _SelfieActions({
    required this.state,
    required this.onCapture,
    required this.onRetake,
    required this.isSubmitting,
    required this.onContinue,
  });

  final AttendanceSelfieState state;
  final VoidCallback onCapture;
  final VoidCallback onRetake;
  final bool isSubmitting;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (state.hasCapturedPhoto) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final useStackedButtons = constraints.maxWidth < 360;
          final retakeButton = AppButton(
            label: 'Ambil Ulang',
            icon: Icons.refresh_rounded,
            size: AppButtonSize.medium,
            variant: AppButtonVariant.secondary,
            onPressed: isSubmitting ? null : onRetake,
          );
          final continueButton = AppButton(
            label: isSubmitting ? 'Menyimpan...' : 'Lanjutkan',
            icon: Icons.arrow_forward_rounded,
            size: AppButtonSize.medium,
            onPressed: isSubmitting ? null : onContinue,
          );

          if (useStackedButtons) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                retakeButton,
                const SizedBox(height: AppSpacing.sm),
                continueButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: retakeButton),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: continueButton),
            ],
          );
        },
      );
    }

    return Center(
      child: _CaptureButton(
        isLoading: state.isCapturing,
        enabled: state.isReady,
        onPressed: onCapture,
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : AppColors.border;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled && !isLoading ? onPressed : null,
        child: Container(
          width: 78,
          height: 72,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 6),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: AppColors.surface,
                      strokeWidth: 3,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = size.shortestSide;
    final guideWidth = shortestSide * 0.56;
    final guideHeight = guideWidth * 1.32;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.48),
      width: guideWidth,
      height: guideHeight.clamp(shortestSide * 0.62, size.height * 0.76),
    );

    final paint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path = Path()..addOval(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 18.0;
      const gapLength = 16.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
