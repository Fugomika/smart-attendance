import 'package:equatable/equatable.dart';

class OfficeModel extends Equatable {
  const OfficeModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  @override
  List<Object?> get props => [id, name, latitude, longitude, radiusMeters];
}
