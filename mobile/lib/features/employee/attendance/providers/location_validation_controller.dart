import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/office_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../../data/services/location_service.dart';
import '../models/location_validation_state.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final locationValidationControllerProvider =
    NotifierProvider<LocationValidationController, LocationValidationState>(
      LocationValidationController.new,
    );

class LocationValidationController extends Notifier<LocationValidationState> {
  static const Distance _distance = Distance();

  @override
  LocationValidationState build() {
    final office = ref.watch(officeRepositoryProvider).getPrimaryOffice();

    return LocationValidationState(
      status: LocationValidationStatus.loading,
      office: office,
      message: 'Mencari lokasi Anda...',
    );
  }

  Future<void> refresh() async {
    final office = ref.read(officeRepositoryProvider).getPrimaryOffice();
    if (office == null) {
      state = const LocationValidationState(
        status: LocationValidationStatus.locationError,
        message: 'Data kantor belum tersedia.',
      );
      return;
    }

    state = LocationValidationState(
      status: LocationValidationStatus.loading,
      office: office,
      message: 'Mencari lokasi Anda...',
    );

    try {
      final location = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      state = _validatedState(
        office: office,
        userLocation: location,
        isFallback: false,
      );
    } on LocationFailure catch (error) {
      state = LocationValidationState(
        status: switch (error.type) {
          LocationFailureType.serviceDisabled =>
            LocationValidationStatus.serviceDisabled,
          LocationFailureType.permissionDenied =>
            LocationValidationStatus.permissionDenied,
          LocationFailureType.unknown => LocationValidationStatus.locationError,
        },
        office: office,
        message: error.message,
      );
    }
  }

  void useFallbackLocation() {
    final office =
        state.office ?? ref.read(officeRepositoryProvider).getPrimaryOffice();
    if (office == null) {
      state = const LocationValidationState(
        status: LocationValidationStatus.locationError,
        message: 'Data kantor belum tersedia.',
      );
      return;
    }

    final fallbackLocation = LatLng(
      office.latitude + 0.00035,
      office.longitude + 0.00025,
    );

    state =
        _validatedState(
          office: office,
          userLocation: fallbackLocation,
          isFallback: true,
        ).copyWith(
          message:
              'Menggunakan lokasi preview karena lokasi real belum tersedia.',
        );
  }

  LocationValidationState _validatedState({
    required OfficeModel office,
    required LatLng userLocation,
    required bool isFallback,
  }) {
    final officeLocation = LatLng(office.latitude, office.longitude);
    final distanceMeters = _distance.as(
      LengthUnit.Meter,
      officeLocation,
      userLocation,
    );
    final isInside = distanceMeters <= office.radiusMeters;

    return LocationValidationState(
      status: isInside
          ? LocationValidationStatus.insideRadius
          : LocationValidationStatus.outsideRadius,
      office: office,
      userLocation: userLocation,
      distanceMeters: distanceMeters,
      isFallback: isFallback,
    );
  }
}
