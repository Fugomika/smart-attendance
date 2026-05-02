import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_avatar_picker.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../providers/auth_provider.dart';

class RegisterPlaceholderScreen extends ConsumerStatefulWidget {
  const RegisterPlaceholderScreen({super.key});

  @override
  ConsumerState<RegisterPlaceholderScreen> createState() =>
      _RegisterPlaceholderScreenState();
}

class _RegisterPlaceholderScreenState
    extends ConsumerState<RegisterPlaceholderScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _positionError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _photoPath;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AppSystemOverlay.darkIcons(
      statusBarColor: AppColors.surface,
      navigationBarColor: AppColors.surface,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buat akun',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Isi data berikut untuk mendaftar',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: AppAvatarPicker(
                      imagePath: _photoPath,
                      label: 'Foto profil (opsional)',
                      onChanged: (path) {
                        setState(() {
                          _photoPath = path;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppFormField(
                    label: 'Nama lengkap',
                    controller: _nameController,
                    hint: 'Contoh: Budi Santoso',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    errorText: _nameError,
                    onChanged: (_) => _clearError(() => _nameError = null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'email@gmail.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (_) => _clearError(() => _emailError = null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormField(
                    label: 'Jabatan',
                    controller: _positionController,
                    hint: 'Contoh: Staff IT',
                    prefixIcon: Icons.work_outline_rounded,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    errorText: _positionError,
                    onChanged: (_) => _clearError(() => _positionError = null),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'Minimal 6 karakter',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    errorText: _passwordError,
                    onChanged: (_) => _clearError(() => _passwordError = null),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormField(
                    label: 'Konfirmasi password',
                    controller: _confirmPasswordController,
                    hint: 'Ulangi password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    errorText: _confirmPasswordError,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) =>
                        _clearError(() => _confirmPasswordError = null),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: authState.isLoading ? 'Memproses...' : 'Daftar',
                    onPressed: authState.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Sudah punya akun?',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(RouteNames.login),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          minimumSize: const Size(48, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Masuk',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearError(VoidCallback clear) {
    setState(clear);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final position = _positionController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Nama lengkap wajib diisi' : null;

      if (email.isEmpty) {
        _emailError = 'Email wajib diisi';
      } else if (!_emailRegex.hasMatch(email)) {
        _emailError = 'Format email tidak valid';
      } else {
        _emailError = null;
      }

      _positionError = position.isEmpty ? 'Jabatan wajib diisi' : null;

      if (password.isEmpty) {
        _passwordError = 'Password wajib diisi';
      } else if (password.length < 6) {
        _passwordError = 'Password minimal 6 karakter';
      } else {
        _passwordError = null;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Konfirmasi password wajib diisi';
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Konfirmasi password tidak sama';
      } else {
        _confirmPasswordError = null;
      }
    });

    final hasError = _nameError != null ||
        _emailError != null ||
        _positionError != null ||
        _passwordError != null ||
        _confirmPasswordError != null;
    if (hasError) {
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).register(
          name: name,
          email: email,
          position: position,
          password: password,
          photoPath: _photoPath,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      final message =
          ref.read(authControllerProvider).errorMessage ??
          'Pendaftaran gagal. Silakan coba lagi.';
      AppSnackBar.error(context, message);
      return;
    }

    AppSnackBar.success(
      context,
      'Pendaftaran berhasil. Silakan masuk dengan akun Anda.',
    );
    context.go(RouteNames.login);
  }
}
