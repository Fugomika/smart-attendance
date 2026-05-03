import '../dummy/dummy_offices.dart';
import '../models/office_model.dart';

class OfficeRepository {
  const OfficeRepository();

  OfficeModel? getPrimaryOffice() {
    return dummyOffices.isEmpty ? null : dummyOffices.first;
  }

  OfficeModel? getOfficeById(String id) {
    for (final office in dummyOffices) {
      if (office.id == id) {
        return office;
      }
    }

    return null;
  }
}
