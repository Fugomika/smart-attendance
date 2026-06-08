class ApiConfig {
  const ApiConfig({this.baseUrl = configuredBaseUrl});

  static const String physicalPhoneBaseUrl = 'http://192.168.1.6:8000/api/v1';
  static const String desktopBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: physicalPhoneBaseUrl,
  );

  final String baseUrl;
}
