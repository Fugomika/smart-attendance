import '../config/app_env.dart';

class ApiConfig {
  ApiConfig({String? baseUrl}) : baseUrl = _resolveBaseUrl(baseUrl);

  final String baseUrl;

  static String _resolveBaseUrl(String? override) {
    if (override == null || override.trim().isEmpty) {
      return AppEnv.apiBaseUrl;
    }

    return AppEnv.normalizeApiBaseUrl(override, source: 'ApiConfig.baseUrl');
  }
}
