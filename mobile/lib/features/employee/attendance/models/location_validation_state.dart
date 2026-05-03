import 'package:latlong2/latlong.dart';

import '../../../../data/models/office_model.dart';

enum LocationValidationStatus {
  loading,
  permissionDenied,
  serviceDisabled,
  locationError,
  insideRadius,
  outsideRadius,
}

class LocationValidationState {
  const LocationValidationState({
    required this.status,
    this.office,
    this.userLocation,
    this.distanceMeters,
    this.message,
    this.isFallback = false,
  });

  final LocationValidationStatus status;
  final OfficeModel? office;
  final LatLng? userLocation;
  final double? distanceMeters;
  final String? message;
  final bool isFallback;

  bool get hasLocation => userLocation != null;

  bool get canContinue =>
      status == LocationValidationStatus.insideRadius ||
      status == LocationValidationStatus.outsideRadius;

  bool get isInsideRadius => status == LocationValidationStatus.insideRadius;

  LatLng? get officeLocation {
    final currentOffice = office;
    if (currentOffice == null) {
      return null;
    }

    return LatLng(currentOffice.latitude, currentOffice.longitude);
  }

  LocationValidationState copyWith({
    LocationValidationStatus? status,
    OfficeModel? office,
    LatLng? userLocation,
    double? distanceMeters,
    String? message,
    bool? isFallback,
    bool clearUserLocation = false,
    bool clearDistance = false,
    bool clearMessage = false,
  }) {
    return LocationValidationState(
      status: status ?? this.status,
      office: office ?? this.office,
      userLocation: clearUserLocation
          ? null
          : userLocation ?? this.userLocation,
      distanceMeters: clearDistance
          ? null
          : distanceMeters ?? this.distanceMeters,
      message: clearMessage ? null : message ?? this.message,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
