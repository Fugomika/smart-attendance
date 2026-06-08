import '../../core/network/api_client.dart';
import '../models/office_model.dart';

class OfficeRepository {
  const OfficeRepository({
    required ApiClient apiClient,
    required List<OfficeModel> offices,
  }) : _apiClient = apiClient,
       _offices = offices;

  final ApiClient _apiClient;
  final List<OfficeModel> _offices;

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

  OfficeModel? getPrimaryOffice() {
    return _offices.isEmpty ? null : _offices.first;
  }

  OfficeModel? getOfficeById(String id) {
    for (final office in _offices) {
      if (office.id == id) {
        return office;
      }
    }

    return null;
  }
}
