import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/office_model.dart';
import '../../../../shared/utils/app_snack_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_form_field.dart';
import '../../../../shared/widgets/app_system_overlay.dart';
import '../models/attendance_location_result.dart';
import '../models/location_validation_state.dart';
import '../providers/location_validation_controller.dart';

class AttendanceLocationValidationScreen extends ConsumerStatefulWidget {
  const AttendanceLocationValidationScreen({super.key});

  @override
  ConsumerState<AttendanceLocationValidationScreen> createState() =>
      _AttendanceLocationValidationScreenState();
}

class _AttendanceLocationValidationScreenState
    extends ConsumerState<AttendanceLocationValidationScreen> {
  static const int _outsideReasonMaxLength = 500;

  final MapController _mapController = MapController();
  LatLng? _lastAutoFitUserLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(locationValidationControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationValidationControllerProvider);
    final officeLocation =
        state.officeLocation ?? const LatLng(-6.200000, 106.816666);
    final userLocation = state.userLocation;
    final mapCenter = userLocation ?? officeLocation;
    final mapPoints = _mapPoints(officeLocation, userLocation);

    _scheduleAutoFit(
      officeLocation: officeLocation,
      userLocation: userLocation,
      mapPoints: mapPoints,
    );

    return AppSystemOverlay.darkIcons(
      statusBarColor: Colors.transparent,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: _MapPreview(
                  mapController: _mapController,
                  center: mapCenter,
                  officeLocation: officeLocation,
                  userLocation: userLocation,
                  visiblePoints: mapPoints,
                  radiusMeters: state.office?.radiusMeters ?? 100,
                ),
              ),
              const Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                child: _LocationAppBar(),
              ),
              Positioned(
                right: AppSpacing.md,
                top: 88,
                child: _MapActionButton(
                  icon: Icons.center_focus_strong_rounded,
                  onTap: () => _fitVisiblePoints(mapPoints),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _LocationStatusCard(
                  state: state,
                  onRetry: () {
                    ref
                        .read(locationValidationControllerProvider.notifier)
                        .refresh();
                  },
                  onUseFallback: () {
                    ref
                        .read(locationValidationControllerProvider.notifier)
                        .useFallbackLocation();
                  },
                  onContinue: () => _handleContinue(context, state),
                  onFocusBoth: () => _fitVisiblePoints(mapPoints),
                  onFocusOffice: () => _mapController.move(officeLocation, 17),
                  onFocusUser: userLocation == null
                      ? null
                      : () => _mapController.move(userLocation, 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LatLng> _mapPoints(LatLng officeLocation, LatLng? userLocation) {
    return userLocation == null
        ? [officeLocation]
        : [officeLocation, userLocation];
  }

  void _fitVisiblePoints(List<LatLng> points) {
    if (points.length < 2) {
      _mapController.move(points.first, 17);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 280),
        maxZoom: 17,
      ),
    );
  }

  void _scheduleAutoFit({
    required LatLng officeLocation,
    required LatLng? userLocation,
    required List<LatLng> mapPoints,
  }) {
    if (userLocation == null || userLocation == _lastAutoFitUserLocation) {
      return;
    }

    _lastAutoFitUserLocation = userLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _fitVisiblePoints(mapPoints);
    });
  }

  void _handleContinue(BuildContext context, LocationValidationState state) {
    if (state.status == LocationValidationStatus.insideRadius) {
      final result = _resultFromState(state, isOutside: false);
      if (result == null) {
        AppSnackBar.error(
          context,
          'Data lokasi belum lengkap. Coba ulangi validasi lokasi.',
        );
        return;
      }

      _handlePreparedResult(context, result);
      return;
    }

    if (state.status == LocationValidationStatus.outsideRadius) {
      _showOutsideReasonSheet(context, state);
      return;
    }

    AppSnackBar.warning(context, 'Validasi lokasi belum siap.');
  }

  AttendanceLocationResult? _resultFromState(
    LocationValidationState state, {
    required bool isOutside,
    String? outsideReason,
  }) {
    final office = state.office;
    final userLocation = state.userLocation;
    final distanceMeters = state.distanceMeters;
    if (office == null || userLocation == null || distanceMeters == null) {
      return null;
    }

    return AttendanceLocationResult(
      office: office,
      userLocation: userLocation,
      distanceMeters: distanceMeters,
      isOutside: isOutside,
      outsideReason: outsideReason,
    );
  }

  void _handlePreparedResult(
    BuildContext context,
    AttendanceLocationResult result,
  ) {
    AppSnackBar.info(
      context,
      result.isOutside
          ? 'Data lokasi dan alasan sudah siap. Selfie akan dibuat pada tahap berikutnya.'
          : 'Data lokasi sudah siap. Selfie akan dibuat pada tahap berikutnya.',
    );
  }

  Future<void> _showOutsideReasonSheet(
    BuildContext context,
    LocationValidationState state,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (sheetContext) {
        return _OutsideReasonSheet(
          distanceText: _OfficeInfoGrid.formatDistance(state.distanceMeters),
          onSubmit: (reason) {
            final result = _resultFromState(
              state,
              isOutside: true,
              outsideReason: reason,
            );
            if (result == null) {
              if (!mounted) {
                return;
              }

              AppSnackBar.error(
                context,
                'Data lokasi belum lengkap. Coba ulangi validasi lokasi.',
              );
              return;
            }

            _handlePreparedResult(context, result);
          },
          onRetry: () {
            ref.read(locationValidationControllerProvider.notifier).refresh();
          },
        );
      },
    );
  }
}

class _OutsideReasonSheet extends StatefulWidget {
  const _OutsideReasonSheet({
    required this.distanceText,
    required this.onSubmit,
    required this.onRetry,
  });

  final String distanceText;
  final ValueChanged<String> onSubmit;
  final VoidCallback onRetry;

  @override
  State<_OutsideReasonSheet> createState() => _OutsideReasonSheetState();
}

class _OutsideReasonSheetState extends State<_OutsideReasonSheet> {
  final TextEditingController _reasonController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda di luar area kantor',
              style: AppTextStyles.h3.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Jarak Anda dari kantor saat ini sekitar ${widget.distanceText}.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppFormField(
              label: 'Alasan',
              controller: _reasonController,
              hint: 'Contoh: kunjungan klien',
              errorText: _errorText,
              isRequired: true,
              minLines: 4,
              maxLines: 5,
              maxLength: _AttendanceLocationValidationScreenState
                  ._outsideReasonMaxLength,
              showCounter: true,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Lanjutkan', onPressed: _submit),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cek ulang lokasi',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRetry();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorText = 'Alasan wajib diisi.';
      });
      return;
    }

    Navigator.of(context).pop();
    widget.onSubmit(reason);
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.mapController,
    required this.center,
    required this.officeLocation,
    required this.userLocation,
    required this.visiblePoints,
    required this.radiusMeters,
  });

  final MapController mapController;
  final LatLng center;
  final LatLng officeLocation;
  final LatLng? userLocation;
  final List<LatLng> visiblePoints;
  final double radiusMeters;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 17,
            initialCameraFit: visiblePoints.length > 1
                ? CameraFit.coordinates(
                    coordinates: visiblePoints,
                    padding: const EdgeInsets.fromLTRB(48, 120, 48, 280),
                    maxZoom: 17,
                  )
                : null,
            minZoom: 3,
            maxZoom: 19,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(-85, -180),
                const LatLng(85, 180),
              ),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kel6_abp.smartattendnace',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: officeLocation,
                  radius: radiusMeters,
                  useRadiusInMeter: true,
                  color: AppColors.success.withAlpha(42),
                  borderColor: AppColors.success,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            if (userLocation != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [officeLocation, userLocation!],
                    color: AppColors.primary,
                    strokeWidth: 4,
                    pattern: StrokePattern.dashed(segments: [10, 8]),
                    borderColor: AppColors.surface,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: officeLocation,
                  width: 48,
                  height: 48,
                  child: const _MapMarker(
                    icon: Icons.business_rounded,
                    backgroundColor: AppColors.success,
                  ),
                ),
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
                    width: 48,
                    height: 48,
                    child: const _MapMarker(
                      icon: Icons.person_pin_circle_rounded,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(226),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Text(
                '(c) OpenStreetMap contributors',
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationAppBar extends StatelessWidget {
  const _LocationAppBar();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _MapActionButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }

                  context.go(RouteNames.employeeHome);
                },
              ),
            ),
            Text(
              'Validasi Lokasi',
              style: AppTextStyles.h3.copyWith(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({
    required this.state,
    required this.onRetry,
    required this.onUseFallback,
    required this.onContinue,
    required this.onFocusBoth,
    required this.onFocusOffice,
    required this.onFocusUser,
  });

  final LocationValidationState state;
  final VoidCallback onRetry;
  final VoidCallback onUseFallback;
  final VoidCallback onContinue;
  final VoidCallback onFocusBoth;
  final VoidCallback onFocusOffice;
  final VoidCallback? onFocusUser;

  @override
  Widget build(BuildContext context) {
    final data = _StatusCardData.fromState(state);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data.color.withAlpha(32),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Icon(data.icon, color: data.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 18,
                        color: data.color,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      data.description,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.isFallback) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlineNotice(
              icon: Icons.info_outline_rounded,
              label:
                  'Mode preview hanya untuk melihat tampilan, bukan untuk mengirim presensi.',
              color: AppColors.warningDark,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _OfficeInfoGrid(state: state),
          const SizedBox(height: AppSpacing.md),
          _MapViewControls(
            onFocusBoth: onFocusBoth,
            onFocusOffice: onFocusOffice,
            onFocusUser: onFocusUser,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.status == LocationValidationStatus.loading)
            const _LoadingLocation()
          else if (state.canContinue)
            AppButton(
              label: state.isInsideRadius
                  ? 'Lanjut Ambil Selfie'
                  : 'Lanjut dengan Alasan',
              icon: state.isInsideRadius
                  ? Icons.camera_alt_rounded
                  : Icons.edit_note_rounded,
              variant: state.isInsideRadius
                  ? AppButtonVariant.success
                  : AppButtonVariant.primary,
              onPressed: onContinue,
            )
          else
            kDebugMode
                ? Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Coba Lagi',
                          icon: Icons.refresh_rounded,
                          size: AppButtonSize.medium,
                          onPressed: onRetry,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: 'Preview',
                          icon: Icons.map_rounded,
                          size: AppButtonSize.medium,
                          variant: AppButtonVariant.secondary,
                          onPressed: onUseFallback,
                        ),
                      ),
                    ],
                  )
                : AppButton(
                    label: 'Coba Lagi',
                    icon: Icons.refresh_rounded,
                    size: AppButtonSize.medium,
                    onPressed: onRetry,
                  ),
        ],
      ),
    );
  }
}

class _OfficeInfoGrid extends StatelessWidget {
  const _OfficeInfoGrid({required this.state});

  final LocationValidationState state;

  @override
  Widget build(BuildContext context) {
    final office = state.office;

    return Column(
      children: [
        _InfoTile(
          label: 'Kantor',
          value: office?.name ?? '-',
          maxValueLines: 1,
          onTap: office == null
              ? null
              : () => _showOfficeDetailSheet(context, office),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: 'Radius',
                value: office == null
                    ? '-'
                    : '${office.radiusMeters.round()} m',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _InfoTile(
                label: 'Jarak Anda',
                value: formatDistance(state.distanceMeters),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String formatDistance(double? meters) {
    if (meters == null) {
      return '-';
    }
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    final kilometers = meters / 1000;
    if (kilometers >= 100) {
      return '${_formatWholeNumber(kilometers.round())} km';
    }

    return '${kilometers.toStringAsFixed(1)} km';
  }

  static String _formatWholeNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  static void _showOfficeDetailSheet(BuildContext context, OfficeModel office) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Kantor',
                  style: AppTextStyles.h3.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(label: 'Nama Kantor', value: office.name),
                _DetailRow(
                  label: 'Latitude',
                  value: office.latitude.toStringAsFixed(6),
                ),
                _DetailRow(
                  label: 'Longitude',
                  value: office.longitude.toStringAsFixed(6),
                ),
                _DetailRow(
                  label: 'Radius Presensi',
                  value: '${office.radiusMeters.round()} m',
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Tutup',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapViewControls extends StatelessWidget {
  const _MapViewControls({
    required this.onFocusBoth,
    required this.onFocusOffice,
    required this.onFocusUser,
  });

  final VoidCallback onFocusBoth;
  final VoidCallback onFocusOffice;
  final VoidCallback? onFocusUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lihat posisi',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _MapViewButton(
                label: 'Keduanya',
                icon: Icons.center_focus_strong_rounded,
                onTap: onFocusBoth,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MapViewButton(
                label: 'Kantor',
                icon: Icons.business_rounded,
                onTap: onFocusOffice,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _MapViewButton(
                label: 'Saya',
                icon: Icons.my_location_rounded,
                onTap: onFocusUser,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapViewButton extends StatelessWidget {
  const _MapViewButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.canvasNeutral : AppColors.softBlue,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: onTap == null ? AppColors.textMuted : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: onTap == null
                        ? AppColors.textMuted
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.maxValueLines = 2,
    this.onTap,
  });

  final String label;
  final String value;
  final int maxValueLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      maxLines: maxValueLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLocation extends StatelessWidget {
  const _LoadingLocation();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Mengambil lokasi terkini...',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: onTap == null ? AppColors.textMuted : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.backgroundColor});

  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withAlpha(36),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.surface, size: 28),
    );
  }
}

class _StatusCardData {
  const _StatusCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  static _StatusCardData fromState(LocationValidationState state) {
    return switch (state.status) {
      LocationValidationStatus.loading => _StatusCardData(
        title: 'Mencari Lokasi',
        description: state.message ?? 'Mohon tunggu sebentar.',
        icon: Icons.location_searching_rounded,
        color: AppColors.primary,
      ),
      LocationValidationStatus.permissionDenied => _StatusCardData(
        title: 'Izin Lokasi Diperlukan',
        description:
            'Aktifkan izin lokasi agar aplikasi dapat memeriksa radius presensi.',
        icon: Icons.location_disabled_rounded,
        color: AppColors.dangerDark,
      ),
      LocationValidationStatus.serviceDisabled => _StatusCardData(
        title: 'Lokasi Belum Aktif',
        description: 'Aktifkan layanan lokasi di perangkat, lalu coba lagi.',
        icon: Icons.gps_off_rounded,
        color: AppColors.warningDark,
      ),
      LocationValidationStatus.locationError => _StatusCardData(
        title: 'Lokasi Belum Terbaca',
        description:
            'Pastikan GPS aktif dan sinyal lokasi stabil, lalu coba lagi.',
        icon: Icons.wrong_location_rounded,
        color: AppColors.warningDark,
      ),
      LocationValidationStatus.insideRadius => _StatusCardData(
        title: 'Lokasi Sesuai',
        description: 'Anda berada dalam radius presensi.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      LocationValidationStatus.outsideRadius => const _StatusCardData(
        title: 'Di Luar Radius',
        description:
            'Anda tetap bisa lanjut dengan alasan presensi dari luar kantor.',
        icon: Icons.info_rounded,
        color: AppColors.primary,
      ),
    };
  }
}
