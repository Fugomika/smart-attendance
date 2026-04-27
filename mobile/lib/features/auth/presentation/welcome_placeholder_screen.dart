import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class WelcomePlaceholderScreen extends StatelessWidget {
  const WelcomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Smart Attendance',
      description: 'Boilerplate welcome route is ready.',
      actions: [
        ElevatedButton(
          onPressed: () => context.go(RouteNames.login),
          child: const Text('Ke Login'),
        ),
      ],
    );
  }
}
