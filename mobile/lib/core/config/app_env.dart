import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get apiBaseUrl => normalizeApiBaseUrl(
    dotenv.env['API_BASE_URL'] ?? '',
    source: 'API_BASE_URL pada mobile/.env',
  );

  static bool get showDebugPreview => _readBool('SHOW_DEBUG_PREVIEW');

  static void validate() {
    final _ = apiBaseUrl;
    final _ = showDebugPreview;
  }

  static String normalizeApiBaseUrl(String value, {required String source}) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    final isHttpUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;

    if (!isHttpUrl) {
      throw StateError(
        '$source wajib berisi URL HTTP/HTTPS yang valid, misalnya '
        'http://192.168.1.5:8000/api/v1',
      );
    }

    return normalized;
  }

  static bool _readBool(String key, {bool fallback = false}) {
    final value = dotenv.env[key]?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return fallback;
    }

    if (value == 'true') {
      return true;
    }
    if (value == 'false') {
      return false;
    }

    throw StateError('$key pada mobile/.env wajib bernilai true atau false');
  }
}
