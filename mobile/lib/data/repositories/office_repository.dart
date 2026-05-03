import '../models/office_model.dart';

class OfficeRepository {
  const OfficeRepository(this._offices);

  final List<OfficeModel> _offices;

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
