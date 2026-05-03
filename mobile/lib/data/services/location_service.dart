import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationFailureType { serviceDisabled, permissionDenied, unknown }

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;
}

class LocationService {
  const LocationService();

  Future<LatLng> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'Layanan lokasi belum aktif.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureType.permissionDenied,
        'Izin lokasi belum diberikan.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationFailure(
        LocationFailureType.unknown,
        'Lokasi belum berhasil ditemukan. Coba lagi beberapa saat.',
      );
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'Layanan lokasi belum aktif.',
      );
    } on PermissionDeniedException {
      throw const LocationFailure(
        LocationFailureType.permissionDenied,
        'Izin lokasi belum diberikan.',
      );
    } catch (_) {
      throw const LocationFailure(
        LocationFailureType.unknown,
        'Terjadi kendala saat membaca lokasi.',
      );
    }
  }
}
