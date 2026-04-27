import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/enums/user_role.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/placeholder_screen.dart';
import '../providers/auth_provider.dart';

class LoginPlaceholderScreen extends ConsumerWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return PlaceholderScreen(
      title: 'Login',
      description:
          authState.errorMessage ?? 'Pilih akun dummy untuk preview role.',
      actions: [
        AppButton(
          label: 'Login Employee',
          onPressed: authState.isLoading
              ? null
              : () => _login(
                  ref,
                  context,
                  email: 'user@gmail.com',
                  password: 'password',
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Login Admin',
          variant: AppButtonVariant.outline,
          onPressed: authState.isLoading
              ? null
              : () => _login(
                  ref,
                  context,
                  email: 'admin@gmail.com',
                  password: 'password',
                ),
        ),
      ],
    );
  }

  Future<void> _login(
    WidgetRef ref,
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);

    if (!success || !context.mounted) {
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
