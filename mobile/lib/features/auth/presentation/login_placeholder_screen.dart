import 'package:flutter/material.dart';
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
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Selamat datang!',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Silakan masuk untuk melanjutkan',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Image.asset(
                      AppAssets.loginIllustration,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AuthInputField(
                    controller: _emailController,
                    hintText: 'email@gmail.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    enableSuggestions: false,
                    onChanged: (_) => _clearEmailError(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AuthInputField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    errorText: _passwordError,
                    enableSuggestions: false,
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
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isRemembered,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                          side: const BorderSide(
                            color: AppColors.textSecondary,
                            width: 1.5,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isRemembered = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'ingat saya',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go(RouteNames.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'lupa password?',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: authState.isLoading ? 'Memproses...' : 'Masuk',
                    onPressed: authState.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Belum punya akun?',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 14,
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
                          minimumSize: Size.zero,
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
      _emailError = email.isEmpty ? 'Email wajib diisi.' : null;
      _passwordError = password.isEmpty ? 'Password wajib diisi.' : null;
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
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
    this.suffixIcon,
    this.enableSuggestions = true,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: enableSuggestions,
      style: AppTextStyles.h2.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textMuted,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        errorText: errorText,
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Icon(icon, color: AppColors.textSecondary, size: 24),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 56),
        suffixIcon: suffixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: IconTheme(
                  data: const IconThemeData(
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  child: suffixIcon!,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 1.6),
        errorBorder: _border(AppColors.danger, width: 1.6),
        focusedErrorBorder: _border(AppColors.danger, width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.large),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
