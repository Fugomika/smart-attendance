import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_selfie_state.dart';

final attendanceSelfieControllerProvider =
    NotifierProvider.autoDispose<
      AttendanceSelfieController,
      AttendanceSelfieState
    >(AttendanceSelfieController.new);

class AttendanceSelfieController extends Notifier<AttendanceSelfieState> {
  CameraController? _cameraController;
  bool _isDisposed = false;

  CameraController? get cameraController => _cameraController;

  @override
  AttendanceSelfieState build() {
    ref.onDispose(() {
      _isDisposed = true;
      unawaited(_disposeCamera());
    });

    return const AttendanceSelfieState.initializing();
  }

  Future<void> initialize() async {
    if (_isDisposed) {
      return;
    }

    state = const AttendanceSelfieState.initializing();
    await _disposeCamera();

    try {
      final cameras = await availableCameras();
      final frontCamera = _frontCamera(cameras);
      if (frontCamera == null) {
        _setState(
          const AttendanceSelfieState(
            status: AttendanceSelfieStatus.cameraUnavailable,
            message: 'Kamera depan tidak tersedia di perangkat ini.',
          ),
        );
        return;
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _cameraController = controller;

      await controller.initialize();
      if (!controller.value.isInitialized) {
        _setState(
          const AttendanceSelfieState(
            status: AttendanceSelfieStatus.error,
            message: 'Kamera belum siap. Coba lagi.',
          ),
        );
        return;
      }

      _setState(
        const AttendanceSelfieState(
          status: AttendanceSelfieStatus.ready,
          message: 'Kamera siap digunakan.',
        ),
      );
    } on CameraException catch (error) {
      await _disposeCamera();
      _setState(_stateFromCameraException(error));
    } catch (_) {
      await _disposeCamera();
      _setState(
        const AttendanceSelfieState(
          status: AttendanceSelfieStatus.error,
          message: 'Kamera gagal dibuka. Coba lagi.',
        ),
      );
    }
  }

  Future<void> retry() => initialize();

  Future<void> capture() async {
    final controller = _cameraController;
    if (_isDisposed || controller == null || !controller.value.isInitialized) {
      _setState(
        const AttendanceSelfieState(
          status: AttendanceSelfieStatus.error,
          message: 'Kamera belum siap. Coba lagi.',
        ),
      );
      return;
    }

    if (controller.value.isTakingPicture) {
      return;
    }

    _setState(
      state.copyWith(
        status: AttendanceSelfieStatus.capturing,
        clearMessage: true,
      ),
    );

    try {
      final photo = await controller.takePicture();
      _setState(
        AttendanceSelfieState(
          status: AttendanceSelfieStatus.captured,
          selfiePath: photo.path,
          capturedAt: DateTime.now(),
          message: 'Selfie berhasil diambil.',
        ),
      );
    } on CameraException catch (error) {
      _setState(_stateFromCameraException(error));
    } catch (_) {
      _setState(
        const AttendanceSelfieState(
          status: AttendanceSelfieStatus.error,
          message: 'Gagal mengambil foto. Coba lagi.',
        ),
      );
    }
  }

  void retake() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _setState(
        const AttendanceSelfieState(
          status: AttendanceSelfieStatus.error,
          message: 'Kamera belum siap. Coba lagi.',
        ),
      );
      return;
    }

    _setState(
      const AttendanceSelfieState(
        status: AttendanceSelfieStatus.ready,
        message: 'Kamera siap digunakan.',
      ),
    );
  }

  CameraDescription? _frontCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }

    return null;
  }

  AttendanceSelfieState _stateFromCameraException(CameraException error) {
    if (_isPermissionDenied(error.code)) {
      return const AttendanceSelfieState(
        status: AttendanceSelfieStatus.permissionDenied,
        message:
            'Izin kamera ditolak. Berikan izin kamera untuk mengambil selfie.',
      );
    }

    return AttendanceSelfieState(
      status: AttendanceSelfieStatus.error,
      message: error.description ?? 'Kamera gagal digunakan. Coba lagi.',
    );
  }

  bool _isPermissionDenied(String code) {
    return code == 'CameraAccessDenied' ||
        code == 'CameraAccessDeniedWithoutPrompt' ||
        code == 'CameraAccessRestricted' ||
        code == 'cameraPermission';
  }

  void _setState(AttendanceSelfieState nextState) {
    if (_isDisposed) {
      return;
    }

    state = nextState;
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    await controller?.dispose();
  }
}
