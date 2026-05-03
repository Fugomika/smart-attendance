import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({required this.isAdminProfile, super.key});

  final bool isAdminProfile;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text('Ubah Password', style: AppTextStyles.h2),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      AppFormField(
                        label: 'Password Lama',
                        hint: 'Masukkan password lama',
                        controller: _oldPasswordController,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: _PasswordToggle(
                          isObscured: _obscureOldPassword,
                          onPressed: () {
                            setState(() {
                              _obscureOldPassword = !_obscureOldPassword;
                            });
                          },
                        ),
                        obscureText: _obscureOldPassword,
                        errorText: _oldPasswordError,
                        isRequired: true,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearOldPasswordError(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppFormField(
                        label: 'Password Baru',
                        hint: 'Minimal 6 karakter',
                        controller: _newPasswordController,
                        prefixIcon: Icons.lock_reset_rounded,
                        suffixIcon: _PasswordToggle(
                          isObscured: _obscureNewPassword,
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        obscureText: _obscureNewPassword,
                        errorText: _newPasswordError,
                        isRequired: true,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _clearNewPasswordErrors(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppFormField(
                        label: 'Konfirmasi Password',
                        hint: 'Ulangi password baru',
                        controller: _confirmPasswordController,
                        prefixIcon: Icons.verified_user_outlined,
                        suffixIcon: _PasswordToggle(
                          isObscured: _obscureConfirmPassword,
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        obscureText: _obscureConfirmPassword,
                        errorText: _confirmPasswordError,
                        isRequired: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => _clearConfirmPasswordError(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Simpan Password',
                  icon: Icons.save_rounded,
                  onPressed: _savePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _savePassword() {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _oldPasswordError = oldPassword.isEmpty
          ? 'Password lama wajib diisi.'
          : null;
      _newPasswordError = newPassword.isEmpty
          ? 'Password baru wajib diisi.'
          : newPassword.length < 6
          ? 'Password baru minimal 6 karakter.'
          : null;
      _confirmPasswordError = confirmPassword.isEmpty
          ? 'Konfirmasi password wajib diisi.'
          : confirmPassword != newPassword
          ? 'Konfirmasi password tidak sama.'
          : null;
    });

    if (_oldPasswordError != null ||
        _newPasswordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    AppSnackBar.success(context, 'Password berhasil diperbarui.');
    _goBack();
  }

  void _clearOldPasswordError() {
    if (_oldPasswordError != null) {
      setState(() => _oldPasswordError = null);
    }
  }

  void _clearNewPasswordErrors() {
    if (_newPasswordError != null || _confirmPasswordError != null) {
      setState(() {
        _newPasswordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  void _clearConfirmPasswordError() {
    if (_confirmPasswordError != null) {
      setState(() => _confirmPasswordError = null);
    }
  }

  void _goBack() {
    context.go(
      widget.isAdminProfile
          ? RouteNames.adminProfile
          : RouteNames.employeeProfile,
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.isObscured, required this.onPressed});

  final bool isObscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isObscured ? 'Tampilkan password' : 'Sembunyikan password',
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: onPressed,
    );
  }
}
