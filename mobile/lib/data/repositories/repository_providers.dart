import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/storage/auth_token_store.dart';
import 'admin_repository.dart';
import 'attendance_repository.dart';
import 'auth_repository.dart';
import 'file_repository.dart';
import 'office_repository.dart';
import 'profile_repository.dart';

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig();
});

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return AuthTokenStore();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(authTokenStoreProvider);
  return ApiClient(
    config: ref.watch(apiConfigProvider),
    tokenReader: tokenStore.readToken,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  );
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepository(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(apiClient: ref.watch(apiClientProvider));
});

final officeRepositoryProvider = Provider<OfficeRepository>((ref) {
  return OfficeRepository(apiClient: ref.watch(apiClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(apiClient: ref.watch(apiClientProvider));
});
