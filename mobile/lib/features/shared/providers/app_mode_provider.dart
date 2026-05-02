import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_mode.dart';
import '../../../core/enums/user_role.dart';

class AppModeController extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.employee;

  void setModeForRole({required UserRole role, required AppMode mode}) {
    if (role == UserRole.employee) {
      state = AppMode.employee;
      return;
    }

    state = mode;
  }

  void enterEmployeeMode() {
    state = AppMode.employee;
  }

  void enterAdminMode({required UserRole role}) {
    if (role != UserRole.admin) {
      state = AppMode.employee;
      return;
    }

    state = AppMode.admin;
  }

  void reset() {
    state = AppMode.employee;
  }
}

final appModeProvider = NotifierProvider<AppModeController, AppMode>(
  AppModeController.new,
);
