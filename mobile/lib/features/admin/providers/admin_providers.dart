import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/repository_providers.dart';

final employeeListProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).getEmployees();
});

final adminSummaryProvider = Provider<AdminSummary>((ref) {
  return ref.watch(adminRepositoryProvider).getTodaySummary();
});
