import '../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  const AttendanceRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AttendanceModel?> getTodayAttendanceFromApi({
    required String userId,
  }) async {
    final response = await _apiClient.get<AttendanceModel?>(
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
    final response = await _apiClient.get<AttendanceHistoryResult>(
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
    final response = await _apiClient.get<AttendanceModel>(
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
    final response = await _apiClient.post<AttendanceModel>(
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
    final response = await _apiClient.post<AttendanceModel>(
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
