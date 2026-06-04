import 'package:latlong2/latlong.dart';

import '../../data/models/attendance_model.dart';
import '../../data/models/office_model.dart';

class AttendanceLocationDetail {
  const AttendanceLocationDetail({
    required this.officeName,
    required this.radiusLabel,
    required this.coordinateLabel,
    required this.distanceLabel,
    required this.googleMapsUri,
  });

  final String officeName;
  final String radiusLabel;
  final String coordinateLabel;
  final String distanceLabel;
  final Uri? googleMapsUri;

  static AttendanceLocationDetail resolve({
    required AttendanceModel attendance,
    required OfficeModel? office,
  }) {
    final userLat = attendance.clockInLat;
    final userLng = attendance.clockInLng;
    final hasUserCoordinate = userLat != null && userLng != null;

    final officeLat = office?.latitude;
    final officeLng = office?.longitude;
    final hasOfficeCoordinate = officeLat != null && officeLng != null;

    final distanceMeters = hasUserCoordinate && hasOfficeCoordinate
        ? const Distance().as(
            LengthUnit.Meter,
            LatLng(officeLat, officeLng),
            LatLng(userLat, userLng),
          )
        : null;

    return AttendanceLocationDetail(
      officeName: office?.name ?? '-',
      radiusLabel: office == null ? '-' : _formatDistance(office.radiusMeters),
      coordinateLabel: hasUserCoordinate
          ? '${userLat.toStringAsFixed(6)}, ${userLng.toStringAsFixed(6)}'
          : '-',
      distanceLabel: distanceMeters == null
          ? '-'
          : _formatDistance(distanceMeters),
      googleMapsUri: hasUserCoordinate && hasOfficeCoordinate
          ? Uri.https('www.google.com', '/maps/dir/', {
              'api': '1',
              'origin':
                  '${officeLat.toStringAsFixed(6)},${officeLng.toStringAsFixed(6)}',
              'destination':
                  '${userLat.toStringAsFixed(6)},${userLng.toStringAsFixed(6)}',
            })
          : null,
    );
  }

  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      final kilometers = meters / 1000;
      return '${kilometers.toStringAsFixed(kilometers >= 10 ? 0 : 1)} km';
    }

    return '${meters.round()} m';
  }
}
