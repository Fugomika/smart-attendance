import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../auth/providers/auth_provider.dart';

final employeeAttendanceHistoryProvider = FutureProvider<List<AttendanceModel>>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const [];
    }

    final selectedMonth = ref.watch(employeeAttendanceSelectedMonthProvider);
    final result = await _readProtected(
      ref,
      () => ref
          .watch(attendanceRepositoryProvider)
          .getHistoryFromApi(userId: user.id, month: selectedMonth),
    );
    final history = [...result.records];

    history.sort(
      (first, second) => second.attendanceDate.compareTo(first.attendanceDate),
    );

    return history;
  },
);

final employeeAttendanceHistoryMonthsProvider = Provider<List<DateTime>>((ref) {
  final now = DateTime.now();
  return List<DateTime>.generate(12, (index) {
    return DateTime(now.year, now.month - index);
  }, growable: false);
});

class EmployeeAttendanceSelectedMonthController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime? month) {
    state = month == null ? null : DateTime(month.year, month.month);
  }
}

final employeeAttendanceSelectedMonthProvider =
    NotifierProvider<EmployeeAttendanceSelectedMonthController, DateTime?>(
      EmployeeAttendanceSelectedMonthController.new,
    );

final employeeAttendanceDetailProvider =
    FutureProvider.family<AttendanceModel?, String>((ref, attendanceId) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return null;
      }

      return _readProtected(
        ref,
        () => ref
            .watch(attendanceRepositoryProvider)
            .getAttendanceDetailFromApi(id: attendanceId, userId: user.id),
      );
    });

Future<T> _readProtected<T>(Ref ref, Future<T> Function() request) async {
  try {
    return await request();
  } on ApiException catch (error) {
    await expireSessionOnUnauthorized(ref, error);
    rethrow;
  }
}
