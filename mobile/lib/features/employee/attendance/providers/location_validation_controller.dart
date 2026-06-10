import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/office_model.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../../data/services/location_service.dart';
import '../../../auth/providers/auth_provider.dart';
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
    return const LocationValidationState(
      status: LocationValidationStatus.loading,
      message: 'Mencari lokasi Anda...',
    );
  }

  Future<void> refresh() async {
    state = const LocationValidationState(
      status: LocationValidationStatus.loading,
      message: 'Mengambil data kantor...',
    );

    try {
      final office = await ref.read(officeRepositoryProvider).getActiveOffice();
      state = LocationValidationState(
        status: LocationValidationStatus.loading,
        office: office,
        message: 'Mencari lokasi Anda...',
      );

      final location = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      state = _validatedState(office: office, userLocation: location);
    } on LocationFailure catch (error) {
      final currentOffice = state.office;
      state = LocationValidationState(
        status: switch (error.type) {
          LocationFailureType.serviceDisabled =>
            LocationValidationStatus.serviceDisabled,
          LocationFailureType.permissionDenied =>
            LocationValidationStatus.permissionDenied,
          LocationFailureType.unknown => LocationValidationStatus.locationError,
        },
        office: currentOffice,
        message: error.message,
      );
    } on ApiException catch (error) {
      if (await expireSessionOnUnauthorized(ref, error)) {
        state = const LocationValidationState(
          status: LocationValidationStatus.locationError,
          message: 'Sesi berakhir. Silakan login kembali',
        );
        return;
      }

      state = LocationValidationState(
        status: LocationValidationStatus.locationError,
        message: _officeErrorMessage(error),
      );
    } catch (_) {
      state = const LocationValidationState(
        status: LocationValidationStatus.locationError,
        message: 'Data kantor aktif gagal dimuat. Coba lagi',
      );
    }
  }

  LocationValidationState _validatedState({
    required OfficeModel office,
    required LatLng userLocation,
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
    );
  }

  String _officeErrorMessage(ApiException error) {
    return switch (error.statusCode) {
      404 => 'Data kantor aktif belum tersedia',
      403 => 'Anda tidak memiliki akses untuk mengambil data kantor',
      _ => error.displayMessage,
    };
  }
}
