import '../config/app_env.dart';

class ApiConfig {
  ApiConfig({String? baseUrl})
    : baseUrl = baseUrl?.trim().isNotEmpty == true
          ? baseUrl!.trim()
          : AppEnv.apiBaseUrl.isNotEmpty
          ? AppEnv.apiBaseUrl
          : physicalPhoneBaseUrl;

  static const String physicalPhoneBaseUrl = 'http://192.168.1.5:8000/api/v1';
  static const String desktopBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  final String baseUrl;
}
