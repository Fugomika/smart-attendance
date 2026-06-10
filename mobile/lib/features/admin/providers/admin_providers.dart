import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/admin_attendance_status_filter.dart';
import '../../../core/enums/attendance_status.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

enum AdminEmployeeStatusFilter {
  all('Semua'),
  active('Aktif'),
  inactive('Nonaktif');

  const AdminEmployeeStatusFilter(this.label);

  final String label;

  String? get apiValue => switch (this) {
    AdminEmployeeStatusFilter.all => null,
    AdminEmployeeStatusFilter.active => 'ACTIVE',
    AdminEmployeeStatusFilter.inactive => 'INACTIVE',
  };
}

class AdminEmployeeListState {
  const AdminEmployeeListState({
    this.records = const [],
    this.query = '',
    this.filter = AdminEmployeeStatusFilter.all,
    this.page = 0,
    this.pageNum = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final List<UserModel> records;
  final String query;
  final AdminEmployeeStatusFilter filter;
  final int page;
  final int pageNum;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final String? errorMessage;

  bool get hasMore => page < pageNum;

  AdminEmployeeListState copyWith({
    List<UserModel>? records,
    String? query,
    AdminEmployeeStatusFilter? filter,
    int? page,
    int? pageNum,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminEmployeeListState(
      records: records ?? this.records,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      pageNum: pageNum ?? this.pageNum,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AdminEmployeeListController extends Notifier<AdminEmployeeListState> {
  static const int _pageSize = 20;
  Timer? _searchDebounce;
  int _requestVersion = 0;

  @override
  AdminEmployeeListState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return const AdminEmployeeListState();
  }

  Future<void> loadInitial() {
    if (state.isLoading) {
      return Future.value();
    }
    return _load(reset: true);
  }

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasLoaded ||
        !state.hasMore) {
      return Future.value();
    }
    return _load(reset: false);
  }

  void setQuery(String value) {
    _requestVersion++;
    state = state.copyWith(query: value, clearError: true);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_load(reset: true));
    });
  }

  void setFilter(AdminEmployeeStatusFilter filter) {
    if (state.filter == filter) {
      return;
    }
    _searchDebounce?.cancel();
    _requestVersion++;
    state = state.copyWith(filter: filter, clearError: true);
    unawaited(_load(reset: true));
  }

  Future<void> _load({required bool reset}) async {
    final requestVersion = ++_requestVersion;
    final requestedPage = reset ? 1 : state.page + 1;

    state = state.copyWith(
      records: reset ? const <UserModel>[] : state.records,
      page: reset ? 0 : state.page,
      pageNum: reset ? 1 : state.pageNum,
      isLoading: reset,
      isLoadingMore: !reset,
      clearError: true,
    );

    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .getUsersFromApi(
            query: state.query,
            status: state.filter.apiValue,
            page: requestedPage,
            pageSize: _pageSize,
          );
      if (requestVersion != _requestVersion) {
        return;
      }

      state = state.copyWith(
        records: reset ? result.records : [...state.records, ...result.records],
        page: result.page,
        pageNum: result.pageNum,
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (requestVersion != _requestVersion) {
        return;
      }
      await expireSessionOnUnauthorized(ref, error);
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        errorMessage: adminReadErrorMessage(error),
      );
    } catch (_) {
      if (requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        errorMessage: 'Data karyawan gagal dimuat. Silakan coba lagi',
      );
    }
  }
}

final adminEmployeeListProvider =
    NotifierProvider<AdminEmployeeListController, AdminEmployeeListState>(
      AdminEmployeeListController.new,
    );

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
  try {
    return await ref
        .watch(adminRepositoryProvider)
        .getSummaryFromApi(selectedDate);
  } on ApiException catch (error) {
    await expireSessionOnUnauthorized(ref, error);
    rethrow;
  }
});

class AdminAttendanceReportState {
  AdminAttendanceReportState({
    DateTime? selectedDate,
    this.records = const [],
    this.query = '',
    this.filter = AdminAttendanceStatusFilter.all,
    this.page = 0,
    this.pageNum = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.errorMessage,
  }) : selectedDate = selectedDate ?? _today();

  final List<AdminAttendanceReportRow> records;
  final DateTime selectedDate;
  final String query;
  final AdminAttendanceStatusFilter filter;
  final int page;
  final int pageNum;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final String? errorMessage;

  bool get hasMore => page < pageNum;

  AdminAttendanceReportState copyWith({
    List<AdminAttendanceReportRow>? records,
    DateTime? selectedDate,
    String? query,
    AdminAttendanceStatusFilter? filter,
    int? page,
    int? pageNum,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminAttendanceReportState(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      pageNum: pageNum ?? this.pageNum,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AdminAttendanceReportController
    extends Notifier<AdminAttendanceReportState> {
  static const int _pageSize = 20;
  Timer? _searchDebounce;
  int _requestVersion = 0;

  @override
  AdminAttendanceReportState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return AdminAttendanceReportState();
  }

  Future<void> loadInitial() {
    if (state.isLoading || state.hasLoaded) {
      return Future.value();
    }
    return _load(reset: true);
  }

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasLoaded ||
        !state.hasMore) {
      return Future.value();
    }
    return _load(reset: false);
  }

  void setDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (state.selectedDate == normalized) {
      return;
    }
    _searchDebounce?.cancel();
    _requestVersion++;
    state = state.copyWith(selectedDate: normalized, clearError: true);
    unawaited(_load(reset: true));
  }

  void setQuery(String value) {
    _requestVersion++;
    state = state.copyWith(query: value, clearError: true);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_load(reset: true));
    });
  }

  void setFilter(AdminAttendanceStatusFilter filter) {
    if (state.filter == filter) {
      return;
    }
    _searchDebounce?.cancel();
    _requestVersion++;
    state = state.copyWith(filter: filter, clearError: true);
    unawaited(_load(reset: true));
  }

  void openWith({
    required DateTime selectedDate,
    required AdminAttendanceStatusFilter filter,
  }) {
    _searchDebounce?.cancel();
    _requestVersion++;
    state = state.copyWith(
      selectedDate: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      ),
      query: '',
      filter: filter,
      hasLoaded: false,
      clearError: true,
    );
    unawaited(_load(reset: true));
  }

  Future<void> _load({required bool reset}) async {
    final requestVersion = ++_requestVersion;
    final requestedPage = reset ? 1 : state.page + 1;
    state = state.copyWith(
      records: reset ? const <AdminAttendanceReportRow>[] : state.records,
      page: reset ? 0 : state.page,
      pageNum: reset ? 1 : state.pageNum,
      isLoading: reset,
      isLoadingMore: !reset,
      clearError: true,
    );

    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .getAttendanceReportFromApi(
            selectedDate: state.selectedDate,
            query: state.query,
            statusFilter: state.filter,
            page: requestedPage,
            pageSize: _pageSize,
          );
      if (requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        records: reset ? result.records : [...state.records, ...result.records],
        page: result.page,
        pageNum: result.pageNum,
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (requestVersion != _requestVersion) {
        return;
      }
      await expireSessionOnUnauthorized(ref, error);
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        errorMessage: adminReadErrorMessage(error),
      );
    } catch (_) {
      if (requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        errorMessage: 'Laporan presensi gagal dimuat. Silakan coba lagi',
      );
    }
  }
}

final adminAttendanceReportProvider =
    NotifierProvider<
      AdminAttendanceReportController,
      AdminAttendanceReportState
    >(AdminAttendanceReportController.new);

final adminEmployeeDetailProvider = FutureProvider.family<UserModel, String>((
  ref,
  employeeId,
) async {
  try {
    return await ref
        .watch(adminRepositoryProvider)
        .getUserDetailFromApi(employeeId);
  } on ApiException catch (error) {
    await expireSessionOnUnauthorized(ref, error);
    rethrow;
  }
});

final adminEmployeeAttendanceHistoryMonthsProvider =
    Provider.family<List<DateTime>, String>((ref, employeeId) {
      final now = DateTime.now();
      return List<DateTime>.generate(12, (index) {
        return DateTime(now.year, now.month - index);
      }, growable: false);
    });

class AdminAttendanceHistoryState {
  AdminAttendanceHistoryState({
    DateTime? selectedMonth,
    this.employeeId,
    this.records = const [],
    this.filter = AdminAttendanceStatusFilter.all,
    this.page = 0,
    this.pageNum = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.errorMessage,
  }) : selectedMonth = selectedMonth ?? _currentMonth();

  final String? employeeId;
  final List<AttendanceModel> records;
  final DateTime selectedMonth;
  final AdminAttendanceStatusFilter filter;
  final int page;
  final int pageNum;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final String? errorMessage;

  bool get hasMore => page < pageNum;

  AdminAttendanceHistoryState copyWith({
    String? employeeId,
    List<AttendanceModel>? records,
    DateTime? selectedMonth,
    AdminAttendanceStatusFilter? filter,
    int? page,
    int? pageNum,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminAttendanceHistoryState(
      employeeId: employeeId ?? this.employeeId,
      records: records ?? this.records,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      pageNum: pageNum ?? this.pageNum,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AdminAttendanceHistoryController
    extends Notifier<AdminAttendanceHistoryState> {
  static const int _pageSize = 20;
  int _requestVersion = 0;

  @override
  AdminAttendanceHistoryState build() => AdminAttendanceHistoryState();

  Future<void> loadInitial(String employeeId) {
    if (state.employeeId == employeeId &&
        (state.isLoading || state.hasLoaded)) {
      return Future.value();
    }
    if (state.employeeId != employeeId) {
      _requestVersion++;
      state = AdminAttendanceHistoryState(employeeId: employeeId);
    }
    return _load(reset: true);
  }

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasLoaded ||
        !state.hasMore) {
      return Future.value();
    }
    return _load(reset: false);
  }

  void setMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    if (state.selectedMonth == normalized) {
      return;
    }
    _requestVersion++;
    state = state.copyWith(selectedMonth: normalized, clearError: true);
    unawaited(_load(reset: true));
  }

  void setFilter(AdminAttendanceStatusFilter filter) {
    if (filter.isNotCheckedIn || state.filter == filter) {
      return;
    }
    _requestVersion++;
    state = state.copyWith(filter: filter, clearError: true);
    unawaited(_load(reset: true));
  }

  Future<void> _load({required bool reset}) async {
    final employeeId = state.employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      return;
    }
    final requestVersion = ++_requestVersion;
    final requestedPage = reset ? 1 : state.page + 1;
    state = state.copyWith(
      records: reset ? const <AttendanceModel>[] : state.records,
      page: reset ? 0 : state.page,
      pageNum: reset ? 1 : state.pageNum,
      isLoading: reset,
      isLoadingMore: !reset,
      clearError: true,
    );

    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .getAttendancesFromApi(
            userId: employeeId,
            month: state.selectedMonth,
            status: state.filter.attendanceStatus,
            page: requestedPage,
            pageSize: _pageSize,
          );
      if (requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        records: reset ? result.records : [...state.records, ...result.records],
        page: result.page,
        pageNum: result.pageNum,
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (requestVersion != _requestVersion) {
        return;
      }
      await expireSessionOnUnauthorized(ref, error);
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        errorMessage: adminReadErrorMessage(error),
      );
    } catch (_) {
      if (requestVersion != _requestVersion) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasLoaded: true,
        errorMessage: 'Riwayat presensi gagal dimuat. Silakan coba lagi',
      );
    }
  }
}

final adminAttendanceHistoryProvider =
    NotifierProvider<
      AdminAttendanceHistoryController,
      AdminAttendanceHistoryState
    >(AdminAttendanceHistoryController.new);

final adminAttendanceDetailProvider =
    FutureProvider.family<AdminAttendanceDetail, String>((
      ref,
      attendanceId,
    ) async {
      try {
        return await ref
            .watch(adminRepositoryProvider)
            .getAttendanceDetailFromApi(attendanceId);
      } on ApiException catch (error) {
        await expireSessionOnUnauthorized(ref, error);
        rethrow;
      }
    });

class AdminAttendanceActionController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> approveAttendance(String attendanceId) {
    return _validate(
      attendanceId: attendanceId,
      status: AttendanceStatus.valid,
    );
  }

  Future<void> rejectAttendance(String attendanceId, {String? note}) {
    return _validate(
      attendanceId: attendanceId,
      status: AttendanceStatus.rejected,
      note: note,
    );
  }

  Future<void> _validate({
    required String attendanceId,
    required AttendanceStatus status,
    String? note,
  }) async {
    if (state) {
      return;
    }
    state = true;
    try {
      await ref
          .read(adminRepositoryProvider)
          .validateAttendanceFromApi(
            attendanceId: attendanceId,
            status: status,
            note: note,
          );
      ref.invalidate(adminAttendanceDetailProvider(attendanceId));
      ref.invalidate(adminSummaryProvider);
      unawaited(ref.read(adminAttendanceHistoryProvider.notifier).refresh());
      unawaited(ref.read(adminAttendanceReportProvider.notifier).refresh());
    } on ApiException catch (error) {
      await expireSessionOnUnauthorized(ref, error);
      rethrow;
    } finally {
      state = false;
    }
  }
}

final adminAttendanceActionProvider =
    NotifierProvider<AdminAttendanceActionController, bool>(
      AdminAttendanceActionController.new,
    );

String adminReadErrorMessage(ApiException error) {
  return switch (error.statusCode) {
    401 => 'Sesi berakhir. Silakan login kembali',
    403 => 'Akses ditolak. Akun ini tidak memiliki akses admin',
    404 => 'Data yang diminta tidak ditemukan',
    422 => error.displayMessage,
    _ => error.displayMessage,
  };
}

String adminAttendanceActionErrorMessage(ApiException error) {
  return switch (error.statusCode) {
    400 => 'Presensi ini sudah tidak berstatus pending',
    401 => 'Sesi berakhir. Silakan login kembali',
    403 => 'Akses ditolak. Akun ini tidak memiliki akses admin',
    404 => 'Data presensi tidak ditemukan',
    422 => error.displayMessage,
    _ => error.displayMessage,
  };
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _currentMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}
