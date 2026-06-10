import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/office_model.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../providers/office_setting_controller.dart';

class OfficeLocationSettingScreen extends ConsumerStatefulWidget {
  const OfficeLocationSettingScreen({super.key});

  @override
  ConsumerState<OfficeLocationSettingScreen> createState() =>
      _OfficeLocationSettingScreenState();
}

class _OfficeLocationSettingScreenState
    extends ConsumerState<OfficeLocationSettingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _radiusController;

  String? _nameError;
  String? _latitudeError;
  String? _longitudeError;
  String? _radiusError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _radiusController = TextEditingController();
    final cachedOffice = ref.read(officeSettingControllerProvider).office;
    if (cachedOffice != null) {
      _populateControllers(cachedOffice);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(officeSettingControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final officeState = ref.watch(officeSettingControllerProvider);
    ref.listen<OfficeSettingState>(officeSettingControllerProvider, (
      previous,
      next,
    ) {
      final office = next.office;
      if (office != null && previous?.office != office) {
        _populateControllers(office);
      }
    });

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.surface,
      navigationBarColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBack,
          ),
          title: Text('Setting Lokasi Kantor', style: AppTextStyles.h2),
        ),
        body: SafeArea(
          child: officeState.isLoading && officeState.office == null
              ? const LoadingState(message: 'Memuat lokasi kantor aktif...')
              : officeState.errorMessage != null && officeState.office == null
              ? EmptyState(
                  icon: Icons.business_rounded,
                  title: 'Lokasi Kantor Tidak Tersedia',
                  message: officeState.errorMessage!,
                  action: AppButton(
                    label: 'Coba Lagi',
                    icon: Icons.refresh_rounded,
                    size: AppButtonSize.medium,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ref
                        .read(officeSettingControllerProvider.notifier)
                        .load(),
                  ),
                )
              : officeState.office == null
              ? const _MissingOffice()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            AppFormField(
                              label: 'Nama Kantor',
                              hint: 'Masukkan nama kantor',
                              controller: _nameController,
                              prefixIcon: Icons.business_outlined,
                              errorText: _nameError,
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _clearNameError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppFormField(
                              label: 'Latitude',
                              hint: 'Contoh: -7.431688',
                              controller: _latitudeController,
                              prefixIcon: Icons.my_location_outlined,
                              errorText: _latitudeError,
                              isRequired: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _clearLatitudeError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppFormField(
                              label: 'Longitude',
                              hint: 'Contoh: 109.381295',
                              controller: _longitudeController,
                              prefixIcon: Icons.place_outlined,
                              errorText: _longitudeError,
                              isRequired: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _clearLongitudeError(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppFormField(
                              label: 'Radius Meter',
                              hint: 'Contoh: 100',
                              controller: _radiusController,
                              prefixIcon: Icons.radio_button_checked_rounded,
                              errorText: _radiusError,
                              isRequired: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => _clearRadiusError(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: officeState.isSaving
                            ? 'Menyimpan...'
                            : 'Simpan Lokasi',
                        icon: Icons.save_rounded,
                        onPressed: officeState.isSaving ? null : _saveOffice,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveOffice() async {
    final name = _nameController.text.trim();
    final latitude = _parseNumber(_latitudeController.text);
    final longitude = _parseNumber(_longitudeController.text);
    final radius = _parseNumber(_radiusController.text);

    setState(() {
      _nameError = name.isEmpty ? 'Nama kantor wajib diisi.' : null;
      _latitudeError = latitude == null
          ? 'Latitude wajib berupa angka.'
          : latitude < -90 || latitude > 90
          ? 'Latitude harus berada antara -90 dan 90.'
          : null;
      _longitudeError = longitude == null
          ? 'Longitude wajib berupa angka.'
          : longitude < -180 || longitude > 180
          ? 'Longitude harus berada antara -180 dan 180.'
          : null;
      _radiusError = radius == null
          ? 'Radius wajib berupa angka.'
          : radius <= 0
          ? 'Radius harus lebih dari 0.'
          : radius % 1 != 0
          ? 'Radius wajib berupa bilangan bulat.'
          : null;
    });

    if (_nameError != null ||
        _latitudeError != null ||
        _longitudeError != null ||
        _radiusError != null) {
      return;
    }

    try {
      await ref
          .read(officeSettingControllerProvider.notifier)
          .saveOffice(
            name: name,
            latitude: latitude!,
            longitude: longitude!,
            radiusMeter: radius!.toInt(),
          );
      if (mounted) {
        AppSnackBar.success(context, 'Lokasi kantor berhasil disimpan.');
        _goBack();
      }
    } on ApiException catch (error) {
      if (mounted) {
        AppSnackBar.error(context, officeSettingErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Lokasi kantor gagal disimpan. Coba lagi.');
      }
    }
  }

  void _populateControllers(OfficeModel office) {
    _nameController.text = office.name;
    _latitudeController.text = office.latitude.toString();
    _longitudeController.text = office.longitude.toString();
    _radiusController.text = office.radiusMeters.toStringAsFixed(0);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _clearNameError() {
    if (_nameError != null) {
      setState(() => _nameError = null);
    }
  }

  void _clearLatitudeError() {
    if (_latitudeError != null) {
      setState(() => _latitudeError = null);
    }
  }

  void _clearLongitudeError() {
    if (_longitudeError != null) {
      setState(() => _longitudeError = null);
    }
  }

  void _clearRadiusError() {
    if (_radiusError != null) {
      setState(() => _radiusError = null);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(RouteNames.adminProfile);
  }
}

class _MissingOffice extends StatelessWidget {
  const _MissingOffice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Data kantor tidak tersedia.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
