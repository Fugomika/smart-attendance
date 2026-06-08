import 'package:equatable/equatable.dart';

class OfficeModel extends Equatable {
  const OfficeModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.isActive = true,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      id: json['id']?.toString() ?? '',
      name: json['officeName']?.toString() ?? json['name']?.toString() ?? '',
      latitude: _doubleFromJson(json['latitude']),
      longitude: _doubleFromJson(json['longitude']),
      radiusMeters: _doubleFromJson(
        json['radiusMeter'] ?? json['radiusMeters'],
      ),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
    );
  }

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    isActive,
  ];
}

double _doubleFromJson(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
