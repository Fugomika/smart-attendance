class ApiValidationError {
  const ApiValidationError({required this.path, required this.message});

  factory ApiValidationError.fromJson(Map<String, dynamic> json) {
    return ApiValidationError(
      path: json['path']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Input tidak valid.',
    );
  }

  final String path;
  final String message;
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errors = const [],
  });

  factory ApiException.network() {
    return const ApiException(
      message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
    );
  }

  factory ApiException.unknown() {
    return const ApiException(message: 'Terjadi kesalahan. Silakan coba lagi.');
  }

  final String message;
  final int? statusCode;
  final List<ApiValidationError> errors;

  String get displayMessage {
    if (errors.isNotEmpty) {
      return errors.first.message;
    }

    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
