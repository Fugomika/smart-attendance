import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/repository_providers.dart';

class AuthState extends Equatable {
  const AuthState({this.user, this.errorMessage, this.isLoading = false});

  final UserModel? user;
  final String? errorMessage;
  final bool isLoading;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    String? errorMessage,
    bool? isLoading,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [user, errorMessage, isLoading];
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.login(email: email, password: password);

    if (user == null) {
      state = const AuthState(errorMessage: 'Email atau password salah.');
      return false;
    }

    state = AuthState(user: user);
    return true;
  }

  void logout() {
    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});
