import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/user_role.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/forgot_password_placeholder_screen.dart';
import '../../features/auth/presentation/login_placeholder_screen.dart';
import '../../features/auth/presentation/register_placeholder_screen.dart';
import '../../features/auth/presentation/welcome_placeholder_screen.dart';
import '../../features/employee/presentation/employee_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: RouteNames.welcome,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = RouteNames.authRoutes.contains(location);
      final isEmployeeRoute = location.startsWith('/employee');
      final isAdminRoute = location.startsWith('/admin');

      if (!authState.isAuthenticated && !isAuthRoute) {
        return RouteNames.login;
      }

      if (authState.isAuthenticated && isAuthRoute) {
        return authState.user!.role == UserRole.admin
            ? RouteNames.adminDashboard
            : RouteNames.employeeHome;
      }

      if (authState.user?.role == UserRole.employee && isAdminRoute) {
        return RouteNames.employeeHome;
      }

      if (authState.user?.role == UserRole.admin && isEmployeeRoute) {
        return RouteNames.adminDashboard;
      }

      return null;
    },
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
        path: RouteNames.register,
        name: RouteNames.registerName,
        builder: (context, state) => const RegisterPlaceholderScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: RouteNames.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordPlaceholderScreen(),
      ),
      GoRoute(
        path: RouteNames.employeeHome,
        name: RouteNames.employeeHomeName,
        builder: (context, state) => const EmployeeShell(currentIndex: 0),
      ),
      GoRoute(
        path: RouteNames.employeeHistory,
        name: RouteNames.employeeHistoryName,
        builder: (context, state) => const EmployeeShell(currentIndex: 1),
      ),
      GoRoute(
        path: RouteNames.employeeNotifications,
        name: RouteNames.employeeNotificationsName,
        builder: (context, state) => const EmployeeShell(currentIndex: 2),
      ),
      GoRoute(
        path: RouteNames.employeeProfile,
        name: RouteNames.employeeProfileName,
        builder: (context, state) => const EmployeeShell(currentIndex: 3),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        name: RouteNames.adminDashboardName,
        builder: (context, state) => const AdminShell(currentIndex: 0),
      ),
      GoRoute(
        path: RouteNames.adminEmployees,
        name: RouteNames.adminEmployeesName,
        builder: (context, state) => const AdminShell(currentIndex: 1),
      ),
      GoRoute(
        path: RouteNames.adminReports,
        name: RouteNames.adminReportsName,
        builder: (context, state) => const AdminShell(currentIndex: 2),
      ),
      GoRoute(
        path: RouteNames.adminProfile,
        name: RouteNames.adminProfileName,
        builder: (context, state) => const AdminShell(currentIndex: 3),
      ),
    ],
  );
});
