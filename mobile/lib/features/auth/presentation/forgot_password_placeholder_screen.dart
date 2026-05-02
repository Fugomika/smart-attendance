import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_field.dart';
import '../../../shared/widgets/app_system_overlay.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPlaceholderScreen extends ConsumerStatefulWidget {
  const ForgotPasswordPlaceholderScreen({super.key});

  @override
  ConsumerState<ForgotPasswordPlaceholderScreen> createState() =>
      _ForgotPasswordPlaceholderScreenState();
}

class _ForgotPasswordPlaceholderScreenState
    extends ConsumerState<ForgotPasswordPlaceholderScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
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
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.go(RouteNames.login),
          ),
        ),
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
                  Text(
                    'Lupa password?',
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Masukkan email akun Anda. Kami akan mengirim instruksi '
                    'untuk reset password jika email terdaftar.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppFormField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'email@gmail.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    errorText: _emailError,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: authState.isLoading
                        ? 'Memproses...'
                        : 'Kirim instruksi',
                    onPressed: authState.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(RouteNames.login),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        minimumSize: const Size(48, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Kembali ke login',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email wajib diisi';
      } else if (!_emailRegex.hasMatch(email)) {
        _emailError = 'Format email tidak valid';
      } else {
        _emailError = null;
      }
    });

    if (_emailError != null) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(email: email);

    if (!mounted) {
      return;
    }

    AppSnackBar.info(
      context,
      'Jika email terdaftar, instruksi reset password akan dikirim.',
    );
    context.go(RouteNames.login);
  }
}
