class ApiResponse<T> {
  const ApiResponse({required this.message, required this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) parseData,
  ) {
    return ApiResponse<T>(
      message: json['message']?.toString() ?? '',
      data: parseData(json['data']),
    );
  }

  final String message;
  final T data;
}
