import '../../core/enums/attendance_status.dart';
import '../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  const AttendanceRepository({
    required List<AttendanceModel> attendances,
    ApiClient? apiClient,
  }) : _attendances = attendances,
       _apiClient = apiClient;

  final List<AttendanceModel> _attendances;
  final ApiClient? _apiClient;

  List<AttendanceModel> get allAttendances =>
      List<AttendanceModel>.unmodifiable(_attendances);

  Future<AttendanceModel?> getTodayAttendanceFromApi({
    required String userId,
  }) async {
    final response = await _requireApiClient().get<AttendanceModel?>(
      '/attendances/today',
      parseData: (json) {
        if (json == null) {
          return null;
        }

        if (json is Map<String, dynamic>) {
          return AttendanceModel.fromJson(json, currentUserId: userId);
        }

        throw const FormatException('Invalid today attendance response.');
      },
    );

    return response.data;
  }

  Future<AttendanceHistoryResult> getHistoryFromApi({
    required String userId,
    int page = 1,
    int pageSize = 100,
    String sortOrder = 'DESC',
    DateTime? month,
  }) async {
    final response = await _requireApiClient().get<AttendanceHistoryResult>(
      '/attendances/history',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'sortOrder': sortOrder,
        if (month != null)
          'month':
              '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}',
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AttendanceHistoryResult.fromJson(json, userId: userId);
        }

        throw const FormatException('Invalid attendance history response.');
      },
    );

    return response.data;
  }

  Future<AttendanceModel> getAttendanceDetailFromApi({
    required String id,
    required String userId,
  }) async {
    final response = await _requireApiClient().get<AttendanceModel>(
      '/attendances/$id',
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AttendanceModel.fromJson(json, currentUserId: userId);
        }

        throw const FormatException('Invalid attendance detail response.');
      },
    );

    return response.data;
  }

  Future<AttendanceModel> clockInToApi({
    required String userId,
    required String officeId,
    required double clockInLat,
    required double clockInLng,
    required bool isOutside,
    required String? outsideReason,
    required String clockInPhotoId,
  }) async {
    final response = await _requireApiClient().post<AttendanceModel>(
      '/attendances/clock-in',
      data: {
        'officeId': officeId,
        'clockInLat': clockInLat,
        'clockInLng': clockInLng,
        'isOutside': isOutside,
        'outsideReason': isOutside ? outsideReason?.trim() : null,
        'clockInPhotoId': clockInPhotoId,
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AttendanceModel.fromJson(json, currentUserId: userId);
        }

        throw const FormatException('Invalid clock-in response.');
      },
    );

    return response.data;
  }

  Future<AttendanceModel> clockOutToApi({
    required String attendanceId,
    required String userId,
  }) async {
    final response = await _requireApiClient().post<AttendanceModel>(
      '/attendances/clock-out',
      data: {'attendanceId': attendanceId},
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return AttendanceModel.fromJson(json, currentUserId: userId);
        }

        throw const FormatException('Invalid clock-out response.');
      },
    );

    return response.data;
  }

  AttendanceModel? getTodayAttendance(String userId) {
    return getAttendanceByDate(userId, DateTime.now());
  }

  AttendanceModel? getAttendanceByDate(String userId, DateTime date) {
    for (final attendance in _attendances) {
      final sameUser = attendance.userId == userId;
      final sameDate = isSameDate(attendance.attendanceDate, date);
      if (sameUser && sameDate) {
        return attendance;
      }
    }

    return null;
  }

  AttendanceModel? getAttendanceById(String id) {
    for (final attendance in _attendances) {
      if (attendance.id == id) {
        return attendance;
      }
    }

    return null;
  }

  List<AttendanceModel> getHistoryByUser(String userId) {
    return _attendances
        .where((attendance) => attendance.userId == userId)
        .toList();
  }

  Future<AttendanceModel> clockIn({
    required String userId,
    required String officeId,
    required DateTime attendanceDate,
    required DateTime clockInTime,
    required double clockInLat,
    required double clockInLng,
    required bool isOutside,
    required String? outsideReason,
    required String clockInPhotoId,
  }) async {
    final existing = getAttendanceByDate(userId, attendanceDate);
    final date = dateOnly(attendanceDate);

    return AttendanceModel(
      id:
          existing?.id ??
          'attendance-$userId-${date.year}${date.month}${date.day}',
      userId: userId,
      officeId: officeId,
      attendanceDate: date,
      status: AttendanceStatus.checkedIn,
      clockInTime: clockInTime,
      clockInLat: clockInLat,
      clockInLng: clockInLng,
      isOutside: isOutside,
      outsideReason: isOutside ? outsideReason : null,
      clockInPhotoId: clockInPhotoId,
    );
  }

  Future<AttendanceModel> clockOut({
    required String attendanceId,
    required DateTime clockOutTime,
  }) async {
    final existing = getAttendanceById(attendanceId);
    if (existing == null) {
      throw StateError('Attendance tidak ditemukan.');
    }
    if (existing.status != AttendanceStatus.checkedIn) {
      throw StateError('Attendance tidak dalam status CHECKED_IN.');
    }

    return AttendanceModel(
      id: existing.id,
      userId: existing.userId,
      officeId: existing.officeId,
      attendanceDate: existing.attendanceDate,
      status: existing.isOutside
          ? AttendanceStatus.pending
          : AttendanceStatus.valid,
      clockInTime: existing.clockInTime,
      clockOutTime: clockOutTime,
      clockInLat: existing.clockInLat,
      clockInLng: existing.clockInLng,
      isOutside: existing.isOutside,
      outsideReason: existing.outsideReason,
      clockInPhotoId: existing.clockInPhotoId,
    );
  }

  Future<AttendanceModel> validateAttendance({
    required String attendanceId,
    required AttendanceStatus targetStatus,
    String? rejectNote,
  }) async {
    final existing = getAttendanceById(attendanceId);
    if (existing == null) {
      throw StateError('Attendance tidak ditemukan.');
    }
    if (existing.status != AttendanceStatus.pending) {
      throw StateError('Attendance tidak dalam status PENDING.');
    }
    if (targetStatus != AttendanceStatus.valid &&
        targetStatus != AttendanceStatus.rejected) {
      throw StateError('Target validasi tidak didukung.');
    }

    return AttendanceModel(
      id: existing.id,
      userId: existing.userId,
      officeId: existing.officeId,
      attendanceDate: existing.attendanceDate,
      status: targetStatus,
      clockInTime: existing.clockInTime,
      clockOutTime: existing.clockOutTime,
      clockInLat: existing.clockInLat,
      clockInLng: existing.clockInLng,
      isOutside: existing.isOutside,
      outsideReason: existing.outsideReason,
      rejectNote: targetStatus == AttendanceStatus.rejected
          ? rejectNote?.trim().isEmpty == true
                ? null
                : rejectNote?.trim()
          : null,
      clockInPhotoId: existing.clockInPhotoId,
    );
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  ApiClient _requireApiClient() {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw StateError('ApiClient belum tersedia untuk AttendanceRepository.');
    }

    return apiClient;
  }
}

class AttendanceHistoryResult {
  const AttendanceHistoryResult({
    required this.records,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.pageNum,
  });

  factory AttendanceHistoryResult.fromJson(
    Map<String, dynamic> json, {
    required String userId,
  }) {
    final rawRecords = json['records'];
    final records = rawRecords is List
        ? rawRecords
              .whereType<Map<String, dynamic>>()
              .map(
                (record) =>
                    AttendanceModel.fromJson(record, currentUserId: userId),
              )
              .toList(growable: false)
        : const <AttendanceModel>[];

    return AttendanceHistoryResult(
      records: records,
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

int _parseInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
