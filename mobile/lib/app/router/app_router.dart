import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_dashboard_placeholder_screen.dart';
import '../../features/auth/presentation/login_placeholder_screen.dart';
import '../../features/auth/presentation/welcome_placeholder_screen.dart';
import '../../features/employee/presentation/employee_home_placeholder_screen.dart';
import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.welcome,
    routes: [
      GoRoute(
        path: RouteNames.welcome,
        name: RouteNames.welcomeName,
        builder: (context, state) => const WelcomePlaceholderScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.loginName,
        builder: (context, state) => const LoginPlaceholderScreen(),
      ),
      GoRoute(
        path: RouteNames.employeeHome,
        name: RouteNames.employeeHomeName,
        builder: (context, state) => const EmployeeHomePlaceholderScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        name: RouteNames.adminDashboardName,
        builder: (context, state) => const AdminDashboardPlaceholderScreen(),
      ),
    ],
  );
}
