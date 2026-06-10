import '../../core/enums/attendance_status.dart';
import '../../core/enums/admin_attendance_status_filter.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/api_date_time_parser.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';

class AdminSummary {
  const AdminSummary({
    required this.present,
    required this.pending,
    required this.absent,
    required this.others,
    required this.total,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    return AdminSummary(
      present: _parseInt(json['present']),
      pending: _parseInt(json['pending']),
      absent: _parseInt(json['absent']),
      others: _parseInt(json['others']),
      total: _parseInt(json['total']),
    );
  }

  final int present;
  final int pending;
  final int absent;
  final int others;
  final int total;
}

class AdminAttendanceReportRow {
  const AdminAttendanceReportRow({
    required this.user,
    required this.selectedDate,
    this.attendance,
  });

  final UserModel user;
  final DateTime selectedDate;
  final AttendanceModel? attendance;

  bool get hasAttendance => attendance != null;
}

class AdminAttendanceDetail {
  const AdminAttendanceDetail({required this.attendance, required this.user});

  factory AdminAttendanceDetail.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw const FormatException('Invalid admin attendance detail user');
    }

    return AdminAttendanceDetail(
      attendance: AttendanceModel.fromJson(json),
      user: UserModel.fromJson(rawUser),
    );
  }

  final AttendanceModel attendance;
  final UserModel user;
}

class AdminRepository {
  const AdminRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AdminSummary> getSummaryFromApi(DateTime selectedDate) async {
    final response = await _apiClient.get<AdminSummary>(
      '/admin/dashboard/summary',
      queryParameters: {'date': _formatDate(selectedDate)},
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AdminSummary.fromJson(json);
        }

        throw const FormatException('Invalid admin summary response');
      },
    );

    return response.data;
  }

  Future<AdminUserListResult> getUsersFromApi({
    String query = '',
    String? status,
    int page = 1,
    int pageSize = 20,
    String sortOrder = 'ASC',
  }) async {
    final response = await _apiClient.get<AdminUserListResult>(
      '/admin/users',
      queryParameters: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'status': ?status,
        'page': page,
        'pageSize': pageSize,
        'sortOrder': sortOrder,
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AdminUserListResult.fromJson(json);
        }

        throw const FormatException('Invalid admin user list response');
      },
    );

    return response.data;
  }

  Future<UserModel> getUserDetailFromApi(String userId) async {
    final response = await _apiClient.get<UserModel>(
      '/admin/users/$userId',
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return UserModel.fromJson(json);
        }

        throw const FormatException('Invalid admin user detail response');
      },
    );

    return response.data;
  }

  Future<AdminAttendanceListResult> getAttendancesFromApi({
    required String userId,
    required DateTime month,
    AttendanceStatus? status,
    int page = 1,
    int pageSize = 20,
    String sortOrder = 'DESC',
  }) async {
    final response = await _apiClient.get<AdminAttendanceListResult>(
      '/admin/attendances',
      queryParameters: {
        'userId': userId,
        'month': _formatMonth(month),
        if (status != null) 'status': _attendanceStatusApiValue(status),
        'page': page,
        'pageSize': pageSize,
        'sortOrder': sortOrder,
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AdminAttendanceListResult.fromJson(json);
        }

        throw const FormatException('Invalid admin attendance list response');
      },
    );

    return response.data;
  }

  Future<AdminAttendanceReportResult> getAttendanceReportFromApi({
    required DateTime selectedDate,
    String query = '',
    AdminAttendanceStatusFilter statusFilter = AdminAttendanceStatusFilter.all,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get<AdminAttendanceReportResult>(
      '/admin/attendances/report',
      queryParameters: {
        'date': _formatDate(selectedDate),
        if (query.trim().isNotEmpty) 'query': query.trim(),
        if (statusFilter != AdminAttendanceStatusFilter.all)
          'status': _reportStatusApiValue(statusFilter),
        'page': page,
        'pageSize': pageSize,
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AdminAttendanceReportResult.fromJson(json);
        }

        throw const FormatException(
          'Invalid admin attendance report response',
        );
      },
    );

    return response.data;
  }

  Future<AdminAttendanceDetail> getAttendanceDetailFromApi(
    String attendanceId,
  ) async {
    final response = await _apiClient.get<AdminAttendanceDetail>(
      '/admin/attendances/$attendanceId',
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AdminAttendanceDetail.fromJson(json);
        }

        throw const FormatException(
          'Invalid admin attendance detail response',
        );
      },
    );

    return response.data;
  }

  Future<AdminAttendanceDetail> validateAttendanceFromApi({
    required String attendanceId,
    required AttendanceStatus status,
    String? note,
  }) async {
    if (status != AttendanceStatus.valid &&
        status != AttendanceStatus.rejected) {
      throw const FormatException(
        'Invalid admin attendance validation status',
      );
    }

    final response = await _apiClient.patch<AdminAttendanceDetail>(
      '/admin/attendances/$attendanceId/validation',
      data: {
        'status': _attendanceStatusApiValue(status),
        if (status == AttendanceStatus.rejected &&
            note != null &&
            note.trim().isNotEmpty)
          'note': note.trim(),
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AdminAttendanceDetail.fromJson(json);
        }

        throw const FormatException(
          'Invalid admin attendance validation response',
        );
      },
    );

    return response.data;
  }
}

class AdminUserListResult {
  const AdminUserListResult({
    required this.records,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.pageNum,
  });

  factory AdminUserListResult.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    final records = rawRecords is List
        ? rawRecords
              .whereType<Map<String, dynamic>>()
              .map(UserModel.fromJson)
              .toList(growable: false)
        : const <UserModel>[];

    return AdminUserListResult(
      records: records,
      count: _parseInt(json['count']),
      page: _parseInt(json['page']),
      pageSize: _parseInt(json['pageSize']),
      pageNum: _parseInt(json['pageNum']),
    );
  }

  final List<UserModel> records;
  final int count;
  final int page;
  final int pageSize;
  final int pageNum;
}

class AdminAttendanceListResult {
  const AdminAttendanceListResult({
    required this.records,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.pageNum,
  });

  factory AdminAttendanceListResult.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceListResult(
      records: _parseAttendanceRecords(json['records']),
      count: _parseInt(json['count']),
      page: _parseInt(json['page']),
      pageSize: _parseInt(json['pageSize']),
      pageNum: _parseInt(json['pageNum']),
    );
  }

  final List<AttendanceModel> records;
  final int count;
  final int page;
  final int pageSize;
  final int pageNum;
}

class AdminAttendanceReportResult {
  const AdminAttendanceReportResult({
    required this.records,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.pageNum,
  });

  factory AdminAttendanceReportResult.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    final records = rawRecords is List
        ? rawRecords
              .whereType<Map<String, dynamic>>()
              .map((record) {
                final rawUser = record['user'];
                final selectedDate = ApiDateTimeParser.dateOnly(
                  record['selectedDate'],
                );
                if (rawUser is! Map<String, dynamic> || selectedDate == null) {
                  throw const FormatException(
                    'Invalid admin attendance report record',
                  );
                }

                final rawAttendance = record['attendance'];
                return AdminAttendanceReportRow(
                  user: UserModel.fromJson(rawUser),
                  selectedDate: selectedDate,
                  attendance: rawAttendance is Map<String, dynamic>
                      ? AttendanceModel.fromJson(rawAttendance)
                      : null,
                );
              })
              .toList(growable: false)
        : const <AdminAttendanceReportRow>[];

    return AdminAttendanceReportResult(
      records: records,
      count: _parseInt(json['count']),
      page: _parseInt(json['page']),
      pageSize: _parseInt(json['pageSize']),
      pageNum: _parseInt(json['pageNum']),
    );
  }

  final List<AdminAttendanceReportRow> records;
  final int count;
  final int page;
  final int pageSize;
  final int pageNum;
}

List<AttendanceModel> _parseAttendanceRecords(Object? rawRecords) {
  if (rawRecords is! List) {
    return const <AttendanceModel>[];
  }

  return rawRecords
      .whereType<Map<String, dynamic>>()
      .map(AttendanceModel.fromJson)
      .toList(growable: false);
}

int _parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatMonth(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$year-$month';
}

String _attendanceStatusApiValue(AttendanceStatus status) {
  return switch (status) {
    AttendanceStatus.checkedIn => 'CHECKED_IN',
    AttendanceStatus.pending => 'PENDING',
    AttendanceStatus.valid => 'VALID',
    AttendanceStatus.rejected => 'REJECTED',
    AttendanceStatus.sick => 'SICK',
    AttendanceStatus.leave => 'LEAVE',
    AttendanceStatus.holiday => 'HOLIDAY',
  };
}

String _reportStatusApiValue(AdminAttendanceStatusFilter filter) {
  if (filter.isNotCheckedIn) {
    return 'NOT_CHECKED_IN';
  }

  final status = filter.attendanceStatus;
  if (status == null) {
    throw const FormatException('Invalid admin attendance report filter');
  }
  return _attendanceStatusApiValue(status);
}
