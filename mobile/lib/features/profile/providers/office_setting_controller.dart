import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/office_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

class OfficeSettingState extends Equatable {
  const OfficeSettingState({
    this.office,
    this.isLoading = false,
    this.isSaving = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final OfficeModel? office;
  final bool isLoading;
  final bool isSaving;
  final bool hasLoaded;
  final String? errorMessage;

  OfficeSettingState copyWith({
    OfficeModel? office,
    bool? isLoading,
    bool? isSaving,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OfficeSettingState(
      office: office ?? this.office,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    office,
    isLoading,
    isSaving,
    hasLoaded,
    errorMessage,
  ];
}

class OfficeSettingController extends Notifier<OfficeSettingState> {
  @override
  OfficeSettingState build() => const OfficeSettingState();

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final office = await ref.read(officeRepositoryProvider).getActiveOffice();
      state = state.copyWith(
        office: office,
        isLoading: false,
        hasLoaded: true,
        clearError: true,
      );
    } on ApiException catch (error) {
      await expireSessionOnUnauthorized(ref, error);
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: officeSettingErrorMessage(error),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'Data kantor aktif gagal dimuat. Silakan coba lagi.',
      );
    }
  }

  Future<void> saveOffice({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeter,
  }) async {
    final current = state.office;
    if (current == null || state.isSaving) {
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await ref
          .read(officeRepositoryProvider)
          .updateActiveOffice(
            officeId: current.id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            radiusMeter: radiusMeter,
          );
      state = state.copyWith(
        office: saved,
        isSaving: false,
        hasLoaded: true,
        clearError: true,
      );
    } on ApiException catch (error) {
      await expireSessionOnUnauthorized(ref, error);
      state = state.copyWith(
        isSaving: false,
        errorMessage: officeSettingErrorMessage(error),
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Lokasi kantor gagal disimpan. Silakan coba lagi.',
      );
      rethrow;
    }
  }
}

final officeSettingControllerProvider =
    NotifierProvider<OfficeSettingController, OfficeSettingState>(
      OfficeSettingController.new,
    );

String officeSettingErrorMessage(ApiException error) {
  return switch (error.statusCode) {
    401 => 'Sesi berakhir. Silakan login kembali.',
    403 => 'Akses ditolak. Akun ini tidak memiliki akses admin.',
    404 => 'Data kantor aktif tidak ditemukan.',
    422 => error.displayMessage,
    _ => error.displayMessage,
  };
}
