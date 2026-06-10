import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_mode.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../shared/providers/app_mode_provider.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  const AuthState.checking()
    : this(status: AuthStatus.checking, isLoading: true);

  const AuthState.unauthenticated({String? errorMessage})
    : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  const AuthState.authenticated({required UserModel user})
    : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool isLoading;

  bool get isChecking => status == AuthStatus.checking;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? isLoading,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, isLoading];
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.checking();

  Future<void> restoreSession() async {
    if (!state.isChecking) {
      return;
    }

    final token = await ref.read(authTokenStoreProvider).readToken();
    if (token == null || token.trim().isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).me();
      _setModeForUser(user);
      state = AuthState.authenticated(user: user);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(authTokenStoreProvider).clear();
        state = const AuthState.unauthenticated();
        return;
      }

      state = AuthState.unauthenticated(errorMessage: error.displayMessage);
    } catch (_) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Sesi tidak dapat dipulihkan. Silakan login kembali',
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: true,
      clearError: true,
    );
    final repository = ref.read(authRepositoryProvider);

    try {
      final user = await repository.login(
        email: email,
        password: password,
        remember: remember,
      );

      if (user == null) {
        state = const AuthState.unauthenticated(
          errorMessage: 'Email atau password salah',
        );
        return false;
      }

      _setModeForUser(user);
      state = AuthState.authenticated(user: user);
      return true;
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _loginErrorMessage(error),
      );
      return false;
    } catch (_) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Login gagal. Silakan coba lagi',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String position,
    required String password,
    String? photoPath,
  }) async {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: true,
      clearError: true,
    );
    final repository = ref.read(authRepositoryProvider);

    try {
      final user = await repository.register(
        name: name,
        email: email,
        position: position,
        password: password,
        photoPath: photoPath,
      );

      if (user == null) {
        state = const AuthState.unauthenticated(
          errorMessage: 'Pendaftaran gagal. Silakan coba lagi',
        );
        return false;
      }

      state = const AuthState.unauthenticated();
      return true;
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _registerErrorMessage(error),
      );
      return false;
    } catch (_) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Pendaftaran gagal. Silakan coba lagi',
      );
      return false;
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: true,
      clearError: true,
    );
    final repository = ref.read(authRepositoryProvider);

    try {
      await repository.requestPasswordReset(email: email);
      state = const AuthState.unauthenticated();
      return true;
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _forgotPasswordErrorMessage(error),
      );
      return false;
    } catch (_) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Permintaan reset password gagal. Silakan coba lagi',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      await ref.read(authTokenStoreProvider).clear();
    }
    ref.read(appModeProvider.notifier).reset();
    state = const AuthState.unauthenticated();
  }

  Future<void> expireSession() async {
    await ref.read(authTokenStoreProvider).clear();
    ref.read(appModeProvider.notifier).reset();
    state = const AuthState.unauthenticated(
      errorMessage: 'Sesi berakhir. Silakan login kembali',
    );
  }

  void replaceCurrentUser(UserModel user) {
    if (!state.isAuthenticated) {
      return;
    }

    if (state.user?.role != user.role) {
      _setModeForUser(user);
    }
    state = AuthState.authenticated(user: user);
  }

  void _setModeForUser(UserModel user) {
    ref
        .read(appModeProvider.notifier)
        .setModeForRole(
          role: user.role,
          mode: user.role == UserRole.admin ? AppMode.admin : AppMode.employee,
        );
  }

  String _loginErrorMessage(ApiException error) {
    return switch (error.statusCode) {
      401 => 'Email atau password salah',
      403 => error.displayMessage,
      422 => error.displayMessage,
      _ => error.displayMessage,
    };
  }

  String _registerErrorMessage(ApiException error) {
    return switch (error.statusCode) {
      409 => 'Email sudah terdaftar',
      422 => error.displayMessage,
      _ => error.displayMessage,
    };
  }

  String _forgotPasswordErrorMessage(ApiException error) {
    return switch (error.statusCode) {
      404 => 'Email tidak terdaftar',
      422 => error.displayMessage,
      _ => error.displayMessage,
    };
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});

Future<bool> expireSessionOnUnauthorized(Ref ref, ApiException error) async {
  if (error.statusCode != 401) {
    return false;
  }

  await ref.read(authControllerProvider.notifier).expireSession();
  return true;
}
