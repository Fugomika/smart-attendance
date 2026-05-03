import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/office_model.dart';

class AttendanceLocationResult extends Equatable {
  const AttendanceLocationResult({
    required this.office,
    required this.userLocation,
    required this.distanceMeters,
    required this.isOutside,
    this.outsideReason,
  });

  final OfficeModel office;
  final LatLng userLocation;
  final double distanceMeters;
  final bool isOutside;
  final String? outsideReason;

  @override
  List<Object?> get props => [
    office,
    userLocation,
    distanceMeters,
    isOutside,
    outsideReason,
  ];
}
