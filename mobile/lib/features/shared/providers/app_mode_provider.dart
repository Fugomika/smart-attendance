import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_mode.dart';

class AppModeController extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.employee;

  void setMode(AppMode mode) {
    state = mode;
  }
}

final appModeProvider = NotifierProvider<AppModeController, AppMode>(
  AppModeController.new,
);
