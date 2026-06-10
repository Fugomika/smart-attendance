import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL']?.trim() ?? '';
  }

  static bool get showDebugPreview {
    return dotenv.env['SHOW_DEBUG_PREVIEW']?.trim().toLowerCase() == 'true';
  }
}
