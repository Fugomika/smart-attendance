import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../shared/presentation/placeholder_screen.dart';

class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Login',
      description: 'Dummy auth will be wired in Batch 2.',
      actions: [
        ElevatedButton(
          onPressed: () => context.go(RouteNames.employeeHome),
          child: const Text('Preview Employee'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => context.go(RouteNames.adminDashboard),
          child: const Text('Preview Admin'),
        ),
      ],
    );
  }
}
