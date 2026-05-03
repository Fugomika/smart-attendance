import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/enums/app_mode.dart';
import '../../../core/enums/user_role.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../../../shared/widgets/profile_avatar_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shared/providers/app_mode_provider.dart';
import '../providers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.isAdminProfile, super.key});

  final bool isAdminProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final appMode = ref.watch(appModeProvider);

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.background,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: profile == null
                ? const _EmptyProfile()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Profil Saya',
                        style: AppTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProfileCard(
                                profile: profile,
                                onEdit: () {
                                  context.go(
                                    isAdminProfile
                                        ? RouteNames.adminProfileEdit
                                        : RouteNames.employeeProfileEdit,
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _ProfileMenuGroup(
                                items: [
                                  _ProfileMenuItem(
                                    icon: Icons.lock_outline_rounded,
                                    label: 'Ubah Password',
                                    onTap: () {
                                      context.go(
                                        isAdminProfile
                                            ? RouteNames
                                                  .adminProfileChangePassword
                                            : RouteNames
                                                  .employeeProfileChangePassword,
                                      );
                                    },
                                  ),
                                  if (isAdminProfile &&
                                      profile.role == UserRole.admin)
                                    _ProfileMenuItem(
                                      icon: Icons.business_rounded,
                                      label: 'Setting Lokasi Kantor',
                                      onTap: () {
                                        context.go(
                                          RouteNames.adminProfileOfficeLocation,
                                        );
                                      },
                                    ),
                                  _ProfileMenuItem(
                                    icon: Icons.info_outline_rounded,
                                    label: 'Tentang Aplikasi',
                                    onTap: () => _showAboutSheet(context),
                                  ),
                                ],
                              ),
                              if (_showSwitchMode(profile, appMode)) ...[
                                const SizedBox(height: AppSpacing.md),
                                _ProfileMenuGroup(
                                  items: [
                                    _ProfileMenuItem(
                                      icon: isAdminProfile
                                          ? Icons.badge_outlined
                                          : Icons.admin_panel_settings_outlined,
                                      label: isAdminProfile
                                          ? 'Beralih ke Mode Karyawan'
                                          : 'Kembali ke Mode Admin',
                                      onTap: () => _switchMode(context, ref),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                      AppButton(
                        label: 'Logout',
                        variant: AppButtonVariant.danger,
                        icon: Icons.logout_rounded,
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).logout();
                          context.go(RouteNames.login);
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  bool _showSwitchMode(ProfileState profile, AppMode appMode) {
    if (profile.role != UserRole.admin) {
      return false;
    }

    return isAdminProfile && appMode == AppMode.admin ||
        !isAdminProfile && appMode == AppMode.employee;
  }

  void _switchMode(BuildContext context, WidgetRef ref) {
    if (isAdminProfile) {
      ref.read(appModeProvider.notifier).enterEmployeeMode();
      context.go(RouteNames.employeeHome);
      AppSnackBar.info(context, 'Berhasil masuk ke Mode Karyawan.');
      return;
    }

    ref.read(appModeProvider.notifier).enterAdminMode(role: UserRole.admin);
    context.go(RouteNames.adminDashboard);
    AppSnackBar.info(context, 'Berhasil kembali ke Mode Admin.');
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Image.asset(AppAssets.logo, width: 72, height: 72),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Smart Attendance',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Versi 1.0.0',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aplikasi presensi internal dengan validasi lokasi dan selfie.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Kelompok 6 - ABP',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Tutup',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onEdit});

  final ProfileState profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.softBlue,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          Row(
            children: [
              ProfileAvatarView(
                photoPath: profile.photoPath,
                name: profile.name,
                size: 88,
                textStyle: AppTextStyles.h2.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTextStyles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.roleLabel,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      profile.email,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            items[index],
            if (index != items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 16),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Data profil tidak tersedia.',
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
