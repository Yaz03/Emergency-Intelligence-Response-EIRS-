import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';

/// Singleton Dio client configured with base URL, timeouts, and interceptors.
class DioClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  DioClient({required SecureStorageService storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  // ── HTTP helpers ────────────────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _performRequest(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _performRequest(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _performRequest(
      () => _dio.put(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _performRequest(
      () => _dio.delete(path, queryParameters: queryParameters),
    );
  }

  // ── Internal ────────────────────────────────────────────────────────────

  Future<Response> _performRequest(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timed out');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response);
      default:
        return ApiException(message: e.message ?? 'Unexpected error');
    }
  }

  ApiException _mapStatusCode(Response? response) {
    final statusCode = response?.statusCode ?? 500;
    final data = response?.data;
    final message = data is Map ? (data['message'] ?? 'Unknown error') : 'Unknown error';

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message: message);
      case 422:
        final errors = data is Map ? data['errors'] as Map<String, dynamic>? : null;
        return ValidationException(message: message, errors: errors);
      case >= 500:
        return ServerException(message: message);
      default:
        return ApiException(message: message, statusCode: statusCode, data: data);
    }
  }
}

// ── Interceptor: Attach JWT ───────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Could implement token‑refresh logic here.
      _storage.clearTokens();
    }
    handler.next(err);
  }
}

// ── Interceptor: Debug logging ────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✖ ${err.response?.statusCode} ${err.requestOptions.uri}');
    handler.next(err);
  }
}
