import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/app_mode.dart';
import '../../core/enums/user_role.dart';
import '../../features/admin/presentation/admin_placeholder_tab.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/forgot_password_placeholder_screen.dart';
import '../../features/auth/presentation/login_placeholder_screen.dart';
import '../../features/auth/presentation/register_placeholder_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/employee/presentation/employee_home_screen.dart';
import '../../features/employee/presentation/employee_placeholder_tab.dart';
import '../../features/employee/presentation/employee_shell.dart';
import '../../features/shared/providers/app_mode_provider.dart';
import '../../shared/utils/app_snack_bar.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RouteNames.welcome,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final appMode = ref.read(appModeProvider);
      final location = state.matchedLocation;
      final isAuthRoute = RouteNames.authRoutes.contains(location);
      final isEmployeeRoute = location.startsWith('/employee');
      final isAdminRoute = location.startsWith('/admin');

      if (!authState.isAuthenticated && !isAuthRoute) {
        return RouteNames.login;
      }

      if (authState.isAuthenticated && isAuthRoute) {
        final user = authState.user!;
        if (user.role == UserRole.employee) {
          return RouteNames.employeeHome;
        }

        return appMode == AppMode.admin
            ? RouteNames.adminDashboard
            : RouteNames.employeeHome;
      }

      if (authState.user?.role == UserRole.employee && isAdminRoute) {
        return RouteNames.employeeHome;
      }

      if (authState.user?.role == UserRole.admin &&
          appMode == AppMode.admin &&
          isEmployeeRoute) {
        return RouteNames.adminDashboard;
      }

      if (authState.user?.role == UserRole.admin &&
          appMode == AppMode.employee &&
          isAdminRoute) {
        return RouteNames.employeeHome;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.welcome,
        name: RouteNames.welcomeName,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.loginName,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginPlaceholderScreen()),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.registerName,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const RegisterPlaceholderScreen()),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: RouteNames.forgotPasswordName,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ForgotPasswordPlaceholderScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return EmployeeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.employeeHome,
                name: RouteNames.employeeHomeName,
                pageBuilder: (context, state) =>
                    _noTransitionPage(state, const EmployeeHomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.employeeHistory,
                name: RouteNames.employeeHistoryName,
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  const EmployeePlaceholderTab(
                    title: 'Riwayat',
                    icon: Icons.work_history_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.employeeProfile,
                name: RouteNames.employeeProfileName,
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  EmployeePlaceholderTab(
                    title: 'Profil',
                    icon: Icons.person_rounded,
                    actionLabel:
                        ref.read(authControllerProvider).user?.role ==
                            UserRole.admin
                        ? 'Kembali ke Mode Admin'
                        : null,
                    onAction:
                        ref.read(authControllerProvider).user?.role ==
                            UserRole.admin
                        ? () {
                            ref
                                .read(appModeProvider.notifier)
                                .enterAdminMode(role: UserRole.admin);
                            context.go(RouteNames.adminDashboard);
                            AppSnackBar.info(
                              context,
                              'Berhasil kembali ke Mode Admin.',
                            );
                          }
                        : null,
                    onLogout: () {
                      ref.read(authControllerProvider.notifier).logout();
                      context.go(RouteNames.login);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminDashboard,
                name: RouteNames.adminDashboardName,
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  const AdminPlaceholderTab(
                    title: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminEmployees,
                name: RouteNames.adminEmployeesName,
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  const AdminPlaceholderTab(
                    title: 'Karyawan',
                    icon: Icons.groups_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminReports,
                name: RouteNames.adminReportsName,
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  const AdminPlaceholderTab(
                    title: 'Laporan',
                    icon: Icons.description_rounded,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminProfile,
                name: RouteNames.adminProfileName,
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  AdminPlaceholderTab(
                    title: 'Profil',
                    icon: Icons.person_rounded,
                    actionLabel: 'Beralih ke Mode Karyawan',
                    onAction: () {
                      ref.read(appModeProvider.notifier).enterEmployeeMode();
                      context.go(RouteNames.employeeHome);
                      AppSnackBar.info(
                        context,
                        'Berhasil masuk ke Mode Karyawan.',
                      );
                    },
                    onLogout: () {
                      ref.read(authControllerProvider.notifier).logout();
                      context.go(RouteNames.login);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    _authSub = ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final authChanged =
          previous?.user != next.user ||
          previous?.errorMessage != next.errorMessage ||
          previous?.isLoading != next.isLoading;
      if (authChanged) {
        notifyListeners();
      }
    });
    _appModeSub = ref.listen<AppMode>(appModeProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }

  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<AppMode> _appModeSub;

  @override
  void dispose() {
    _authSub.close();
    _appModeSub.close();
    super.dispose();
  }
}
