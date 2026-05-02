import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/enums/user_role.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../providers/auth_provider.dart';

class LoginPlaceholderScreen extends ConsumerStatefulWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  ConsumerState<LoginPlaceholderScreen> createState() =>
      _LoginPlaceholderScreenState();
}

class _LoginPlaceholderScreenState
    extends ConsumerState<LoginPlaceholderScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isRemembered = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                    'Selamat datang!',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Silakan masuk untuk melanjutkan',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Image.asset(
                      AppAssets.loginIllustration,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppFormField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'email@gmail.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearEmailError(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFormField(
                    label: 'Password',
                    controller: _passwordController,
                    hint: 'Masukkan password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    errorText: _passwordError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => _clearPasswordError(),
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
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _isRemembered,
                          activeColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                          side: BorderSide(
                            color: _isRemembered
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            width: 1.5,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isRemembered = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Ingat saya',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(RouteNames.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lupa password?',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: authState.isLoading ? 'Memproses...' : 'Masuk',
                    onPressed: authState.isLoading ? null : _submit,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Dev Admin',
                            size: AppButtonSize.medium,
                            variant: AppButtonVariant.secondary,
                            onPressed: authState.isLoading
                                ? null
                                : () => _quickLogin('admin@gmail.com'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Dev Karyawan',
                            size: AppButtonSize.medium,
                            variant: AppButtonVariant.outline,
                            onPressed: authState.isLoading
                                ? null
                                : () => _quickLogin('user@gmail.com'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Belum punya akun?',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(RouteNames.register),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          minimumSize: const Size(48, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Daftar',
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

  void _clearEmailError() {
    if (_emailError == null) {
      return;
    }

    setState(() {
      _emailError = null;
    });
  }

  void _clearPasswordError() {
    if (_passwordError == null) {
      return;
    }

    setState(() {
      _passwordError = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Email wajib diisi' : null;
      _passwordError = password.isEmpty ? 'Password wajib diisi' : null;
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) {
      return;
    }

    if (!success) {
      final message =
          ref.read(authControllerProvider).errorMessage ??
          'Email atau password salah.';
      AppSnackBar.error(context, message);
      return;
    }

    final role = ref.read(authControllerProvider).user!.role;
    context.go(
      role == UserRole.admin
          ? RouteNames.adminDashboard
          : RouteNames.employeeHome,
    );
  }

  Future<void> _quickLogin(String email) async {
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: 'password');

    if (!mounted) {
      return;
    }

    if (!success) {
      final message =
          ref.read(authControllerProvider).errorMessage ??
          'Email atau password salah.';
      AppSnackBar.error(context, message);
      return;
    }

    final role = ref.read(authControllerProvider).user!.role;
    context.go(
      role == UserRole.admin
          ? RouteNames.adminDashboard
          : RouteNames.employeeHome,
    );
  }
}
