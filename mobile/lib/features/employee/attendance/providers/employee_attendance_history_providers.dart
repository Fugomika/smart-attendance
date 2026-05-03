import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/office_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../auth/providers/auth_provider.dart';

final employeeAttendanceHistoryProvider = Provider<List<AttendanceModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }

  final history = [
    ...ref.watch(attendanceRepositoryProvider).getHistoryByUser(user.id),
  ];

  history.sort(
    (first, second) => second.attendanceDate.compareTo(first.attendanceDate),
  );

  return history;
});

final employeeAttendanceHistoryMonthsProvider = Provider<List<DateTime>>((ref) {
  final history = ref.watch(employeeAttendanceHistoryProvider);
  final monthKeys = <String>{};
  final months = <DateTime>[];

  for (final attendance in history) {
    final month = DateTime(
      attendance.attendanceDate.year,
      attendance.attendanceDate.month,
    );
    final key = '${month.year}-${month.month}';

    if (monthKeys.add(key)) {
      months.add(month);
    }
  }

  months.sort((first, second) => second.compareTo(first));
  return months;
});

class EmployeeAttendanceSelectedMonthController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setMonth(DateTime? month) {
    state = month;
  }
}

final employeeAttendanceSelectedMonthProvider =
    NotifierProvider<EmployeeAttendanceSelectedMonthController, DateTime?>(
      EmployeeAttendanceSelectedMonthController.new,
    );

final employeeFilteredAttendanceHistoryProvider =
    Provider<List<AttendanceModel>>((ref) {
      final history = ref.watch(employeeAttendanceHistoryProvider);
      final selectedMonth = ref.watch(employeeAttendanceSelectedMonthProvider);
      final availableMonths = ref.watch(
        employeeAttendanceHistoryMonthsProvider,
      );
      final activeMonth = _resolveActiveMonth(selectedMonth, availableMonths);

      if (activeMonth == null) {
        return const [];
      }

      return history.where((attendance) {
        final date = attendance.attendanceDate;
        return date.year == activeMonth.year && date.month == activeMonth.month;
      }).toList();
    });

final employeeAttendanceDetailProvider =
    Provider.family<AttendanceModel?, String>((ref, attendanceId) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return null;
      }

      final attendance = ref
          .watch(attendanceRepositoryProvider)
          .getAttendanceById(attendanceId);

      if (attendance == null || attendance.userId != user.id) {
        return null;
      }

      return attendance;
    });

final attendanceOfficeProvider = Provider.family<OfficeModel?, String>((
  ref,
  officeId,
) {
  return ref.watch(officeRepositoryProvider).getOfficeById(officeId);
});

DateTime? _firstOrNull(List<DateTime> dates) {
  return dates.isEmpty ? null : dates.first;
}

DateTime? _resolveActiveMonth(
  DateTime? selectedMonth,
  List<DateTime> availableMonths,
) {
  if (selectedMonth == null) {
    return _firstOrNull(availableMonths);
  }

  for (final month in availableMonths) {
    final sameMonth =
        month.year == selectedMonth.year && month.month == selectedMonth.month;
    if (sameMonth) {
      return selectedMonth;
    }
  }

  return _firstOrNull(availableMonths);
}
