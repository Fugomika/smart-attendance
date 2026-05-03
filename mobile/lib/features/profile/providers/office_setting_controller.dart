import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/office_model.dart';
import '../../../data/repositories/repository_providers.dart';

class OfficeSettingState extends Equatable {
  const OfficeSettingState({
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

  factory OfficeSettingState.fromOffice(OfficeModel office) {
    return OfficeSettingState(
      id: office.id,
      name: office.name,
      latitude: office.latitude,
      longitude: office.longitude,
      radiusMeters: office.radiusMeters,
    );
  }

  OfficeSettingState copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
  }) {
    return OfficeSettingState(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, radiusMeters];
}

class OfficeSettingController extends Notifier<OfficeSettingState?> {
  @override
  OfficeSettingState? build() {
    final office = ref.watch(officeRepositoryProvider).getPrimaryOffice();
    if (office == null) {
      return null;
    }

    return OfficeSettingState.fromOffice(office);
  }

  void saveOffice({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) {
    final current = state;
    if (current == null) {
      return;
    }

    state = current.copyWith(
      name: name.trim(),
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }
}

final officeSettingControllerProvider =
    NotifierProvider<OfficeSettingController, OfficeSettingState?>(
      OfficeSettingController.new,
    );
