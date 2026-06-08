import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/admin_attendance_status_filter.dart';
import '../../../core/enums/attendance_status.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/office_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../core/utils/app_date_time_formatter.dart';

final employeeListProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).getAttendanceUsers();
});

enum AdminEmployeeStatusFilter {
  all('Semua'),
  active('Aktif'),
  inactive('Nonaktif');

  const AdminEmployeeStatusFilter(this.label);

  final String label;
}

class AdminEmployeeSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

class AdminEmployeeStatusFilterController
    extends Notifier<AdminEmployeeStatusFilter> {
  @override
  AdminEmployeeStatusFilter build() => AdminEmployeeStatusFilter.all;

  void setFilter(AdminEmployeeStatusFilter filter) {
    state = filter;
  }
}

final adminEmployeeSearchQueryProvider =
    NotifierProvider<AdminEmployeeSearchQueryController, String>(
      AdminEmployeeSearchQueryController.new,
    );

final adminEmployeeStatusFilterProvider =
    NotifierProvider<
      AdminEmployeeStatusFilterController,
      AdminEmployeeStatusFilter
    >(AdminEmployeeStatusFilterController.new);

final filteredEmployeeListProvider = Provider<List<UserModel>>((ref) {
  final employees = ref.watch(employeeListProvider);
  final filter = ref.watch(adminEmployeeStatusFilterProvider);
  final query = ref
      .watch(adminEmployeeSearchQueryProvider)
      .trim()
      .toLowerCase();

  final statusFiltered = employees.where((employee) {
    return switch (filter) {
      AdminEmployeeStatusFilter.all => true,
      AdminEmployeeStatusFilter.active => employee.isActive,
      AdminEmployeeStatusFilter.inactive => !employee.isActive,
    };
  });

  if (query.isEmpty) {
    return statusFiltered.toList();
  }

  return statusFiltered.where((employee) {
    final normalizedName = employee.name.toLowerCase();
    final normalizedEmail = employee.email.toLowerCase();
    return normalizedName.contains(query) || normalizedEmail.contains(query);
  }).toList();
});

class AdminDashboardDateController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final adminDashboardSelectedDateProvider =
    NotifierProvider<AdminDashboardDateController, DateTime>(
      AdminDashboardDateController.new,
    );

final adminSummaryProvider = FutureProvider<AdminSummary>((ref) async {
  final selectedDate = ref.watch(adminDashboardSelectedDateProvider);
  return ref.watch(adminRepositoryProvider).getSummaryByDate(selectedDate);
});

class AdminAttendanceReportDateController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

class AdminAttendanceReportSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final adminAttendanceReportSelectedDateProvider =
    NotifierProvider<AdminAttendanceReportDateController, DateTime>(
      AdminAttendanceReportDateController.new,
    );

final adminAttendanceReportSearchQueryProvider =
    NotifierProvider<AdminAttendanceReportSearchQueryController, String>(
      AdminAttendanceReportSearchQueryController.new,
    );

class AdminAttendanceReportStatusFilterController
    extends Notifier<AdminAttendanceStatusFilter> {
  @override
  AdminAttendanceStatusFilter build() => AdminAttendanceStatusFilter.all;

  void setFilter(AdminAttendanceStatusFilter filter) {
    state = filter;
  }
}

final adminAttendanceReportStatusFilterProvider =
    NotifierProvider<
      AdminAttendanceReportStatusFilterController,
      AdminAttendanceStatusFilter
    >(AdminAttendanceReportStatusFilterController.new);

final adminAttendanceReportRowsProvider =
    FutureProvider<List<AdminAttendanceReportRow>>((ref) async {
      final selectedDate = ref.watch(adminAttendanceReportSelectedDateProvider);
      final query = ref.watch(adminAttendanceReportSearchQueryProvider);
      final statusFilter = ref.watch(adminAttendanceReportStatusFilterProvider);

      return ref
          .watch(adminRepositoryProvider)
          .getAttendanceReportByDate(
            selectedDate: selectedDate,
            query: query,
            statusFilter: statusFilter,
          );
    });

final adminEmployeeDetailProvider = Provider.family<UserModel?, String>((
  ref,
  employeeId,
) {
  return ref.watch(userRepositoryProvider).getAttendanceUserById(employeeId);
});

final adminEmployeeAttendanceHistoryProvider =
    Provider.family<List<AttendanceModel>, String>((ref, employeeId) {
      final history = [
        ...ref.watch(attendanceRepositoryProvider).getHistoryByUser(employeeId),
      ];

      history.sort(
        (first, second) =>
            second.attendanceDate.compareTo(first.attendanceDate),
      );

      return history;
    });

final adminEmployeeAttendanceHistoryMonthsProvider =
    Provider.family<List<DateTime>, String>((ref, employeeId) {
      final now = DateTime.now();
      return List<DateTime>.generate(12, (index) {
        return DateTime(now.year, now.month - index);
      }, growable: false);
    });

class AdminEmployeeSelectedMonthController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime? month) {
    state = month == null ? null : DateTime(month.year, month.month);
  }
}

final adminEmployeeSelectedMonthProvider =
    NotifierProvider<AdminEmployeeSelectedMonthController, DateTime?>(
      AdminEmployeeSelectedMonthController.new,
    );

class AdminEmployeeAttendanceStatusFilterController
    extends Notifier<AdminAttendanceStatusFilter> {
  @override
  AdminAttendanceStatusFilter build() => AdminAttendanceStatusFilter.all;

  void setFilter(AdminAttendanceStatusFilter filter) {
    state = filter;
  }
}

final adminEmployeeAttendanceStatusFilterProvider =
    NotifierProvider<
      AdminEmployeeAttendanceStatusFilterController,
      AdminAttendanceStatusFilter
    >(AdminEmployeeAttendanceStatusFilterController.new);

final adminFilteredEmployeeAttendanceHistoryProvider =
    Provider.family<List<AttendanceModel>, String>((ref, employeeId) {
      final history = ref.watch(
        adminEmployeeAttendanceHistoryProvider(employeeId),
      );
      final selectedMonth =
          ref.watch(adminEmployeeSelectedMonthProvider) ??
          ref
              .watch(adminEmployeeAttendanceHistoryMonthsProvider(employeeId))
              .first;
      final statusFilter = ref.watch(
        adminEmployeeAttendanceStatusFilterProvider,
      );

      return history.where((attendance) {
        final sameMonth = AppDateTimeFormatter.isSameMonth(
          attendance.attendanceDate,
          selectedMonth,
        );
        final sameStatus =
            statusFilter == AdminAttendanceStatusFilter.all ||
            attendance.status == statusFilter.attendanceStatus;
        return sameMonth && sameStatus;
      }).toList();
    });

final adminAttendanceOfficeProvider = Provider.family<OfficeModel?, String>((
  ref,
  officeId,
) {
  return ref.watch(officeRepositoryProvider).getOfficeById(officeId);
});

final adminAttendanceDetailProvider = Provider.family<AttendanceModel?, String>(
  (ref, attendanceId) {
    return ref
        .watch(attendanceRepositoryProvider)
        .getAttendanceById(attendanceId);
  },
);

final adminAttendanceUserProvider = Provider.family<UserModel?, String>((
  ref,
  userId,
) {
  return ref.watch(userRepositoryProvider).getAttendanceUserById(userId);
});

class AdminAttendanceActionService {
  const AdminAttendanceActionService(this._attendanceStore);

  final AttendanceStoreController _attendanceStore;

  Future<AttendanceModel> approveAttendance(String attendanceId) {
    return _attendanceStore.validateAttendance(
      attendanceId: attendanceId,
      targetStatus: AttendanceStatus.valid,
    );
  }

  Future<AttendanceModel> rejectAttendance(String attendanceId) {
    return _attendanceStore.validateAttendance(
      attendanceId: attendanceId,
      targetStatus: AttendanceStatus.rejected,
    );
  }
}

final adminAttendanceActionProvider = Provider<AdminAttendanceActionService>((
  ref,
) {
  return AdminAttendanceActionService(
    ref.read(attendanceStoreProvider.notifier),
  );
});
