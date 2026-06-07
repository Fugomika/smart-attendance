import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

typedef TokenReader = Future<String?> Function();

class ApiClient {
  ApiClient({required ApiConfig config, TokenReader? tokenReader})
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    if (tokenReader != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await tokenReader();
            if (token != null && token.trim().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) parseData,
  }) {
    return _send<T>(
      () => _dio.get<Object?>(path, queryParameters: queryParameters),
      parseData: parseData,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) parseData,
  }) {
    return _send<T>(
      () => _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      parseData: parseData,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? json) parseData,
  }) {
    return _send<T>(
      () => _dio.patch<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
      parseData: parseData,
    );
  }

  Future<ApiResponse<T>> _send<T>(
    Future<Response<Object?>> Function() request, {
    required T Function(Object? json) parseData,
  }) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(body, parseData);
      }

      throw ApiException.unknown();
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message =
          data['message']?.toString() ??
          'Terjadi kesalahan. Silakan coba lagi.';
      final rawErrors = data['errors'];
      final errors = rawErrors is List
          ? rawErrors
                .whereType<Map<String, dynamic>>()
                .map(ApiValidationError.fromJson)
                .toList(growable: false)
          : const <ApiValidationError>[];

      return ApiException(
        message: message,
        statusCode: statusCode,
        errors: errors,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException.network();
    }

    return ApiException.unknown();
  }
}
