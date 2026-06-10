import '../../core/network/api_client.dart';
import '../models/office_model.dart';

class OfficeRepository {
  const OfficeRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<OfficeModel> getActiveOffice() async {
    final response = await _apiClient.get<OfficeModel>(
      '/offices/active',
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return OfficeModel.fromJson(json);
        }

        throw const FormatException('Invalid active office response.');
      },
    );

    return response.data;
  }

  Future<OfficeModel> updateActiveOffice({
    required String officeId,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeter,
  }) async {
    final response = await _apiClient.patch<OfficeModel>(
      '/admin/offices/$officeId',
      data: {
        'officeName': name.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeter': radiusMeter,
      },
      parseData: (json) {
        if (json is Map<String, dynamic>) {
          return OfficeModel.fromJson(json);
        }

        throw const FormatException('Invalid active office update response.');
      },
    );

    return response.data;
  }
}
