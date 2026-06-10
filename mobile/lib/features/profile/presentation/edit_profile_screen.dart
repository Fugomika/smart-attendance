import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_avatar_picker.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../providers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({required this.isAdminProfile, super.key});

  final bool isAdminProfile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _positionController;
  String? _initialPhotoPath;
  String? _photoPath;
  String? _nameError;
  String? _positionError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _positionController = TextEditingController(text: profile?.jabatan ?? '');
    _initialPhotoPath = profile?.photoPath;
    _photoPath = profile?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);

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
          title: Text('Edit Profile', style: AppTextStyles.h2),
        ),
        body: SafeArea(
          child: profile == null
              ? const _MissingProfile()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            AppAvatarPicker(
                              imagePath: _photoPath,
                              label: 'Foto profil',
                              onChanged: (path) {
                                setState(() => _photoPath = path);
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppFormField(
                              label: 'Nama Lengkap',
                              hint: 'Masukkan nama lengkap',
                              controller: _nameController,
                              prefixIcon: Icons.person_outline_rounded,
                              errorText: _nameError,
                              isRequired: true,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppFormField(
                              label: 'Email',
                              hint: 'Masukkan email',
                              controller: _emailController,
                              prefixIcon: Icons.email_outlined,
                              enabled: false,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppFormField(
                              label: 'Jabatan',
                              hint: 'Masukkan jabatan',
                              controller: _positionController,
                              prefixIcon: Icons.work_outline_rounded,
                              errorText: _positionError,
                              isRequired: true,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) {
                                if (_positionError != null) {
                                  setState(() => _positionError = null);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _ReadOnlyInfo(
                              label: 'Role',
                              value: profile.roleLabel,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                        icon: Icons.save_rounded,
                        onPressed: _isSaving ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Nama lengkap wajib diisi' : null;
      _positionError = position.isEmpty ? 'Jabatan wajib diisi' : null;
    });

    if (_nameError != null || _positionError != null) {
      return;
    }

    setState(() => _isSaving = true);

    final result = await ref
        .read(profileControllerProvider.notifier)
        .saveProfile(
          name: name,
          jabatan: position,
          photoPath: _photoPath,
          clearPhoto: _photoPath == null && _initialPhotoPath != null,
        );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (!result.isSuccess) {
      AppSnackBar.error(context, result.message ?? 'Profil gagal diperbarui');
      return;
    }

    AppSnackBar.success(
      context,
      result.message ?? 'Profil berhasil diperbarui',
    );
    _goToProfile();
  }

  void _goToProfile() {
    context.go(
      widget.isAdminProfile
          ? RouteNames.adminProfile
          : RouteNames.employeeProfile,
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(
      widget.isAdminProfile
          ? RouteNames.adminProfile
          : RouteNames.employeeProfile,
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
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

class _MissingProfile extends StatelessWidget {
  const _MissingProfile();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Data profil tidak tersedia',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
