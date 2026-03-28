import 'package:dio/dio.dart';
import 'environment.dart';
import 'exceptions.dart';
import 'token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio/io.dart';
import 'dart:io';

/// The central HTTP client for all GreenLoop apps.
///
/// ## Usage
/// ```dart
/// final client = ApiClient(environment: Environment.dev);
///
/// // GET
/// final response = await client.get('/api/pickups/');
///
/// // POST with body
/// final response = await client.post('/api/auth/login/', data: {...});
///
/// // Upload a file
/// final response = await client.postForm('/api/complaints/', formData: FormData.fromMap({...}));
/// ```
///
/// ## Auth
/// - Access token is attached automatically by [AuthInterceptor].
/// - When a 401 is received, [RefreshTokenInterceptor] refreshes the token
///   and retries the original request — invisible to callers.
/// - On terminal auth failure (refresh also 401), [UnauthorizedException] is thrown.
///
/// ## Error mapping
/// All [DioException]s are converted into typed [ApiException] sub-classes by
/// [_mapException].  Apps never need to import Dio.
class ApiClient {
  final Environment environment;
  final TokenStorage tokenStorage;
  late final Dio _dio;

  ApiClient({
    required this.environment,
    TokenStorage? tokenStorage,
  }) : tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = _buildDio();
  }

  // ── Dio construction ──────────────────────────────────────────────────────

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: environment.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Cache Configuration ──────────────────────────────────────────────
    final cacheOptions = CacheOptions(
      store: MemCacheStore(), 
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    // Order matters: logging → cache → auth → refresh
    dio.interceptors.addAll([
      LoggingInterceptor(debug: environment.isDebug),
      DioCacheInterceptor(options: cacheOptions),
      AuthInterceptor(this.tokenStorage),
      RefreshTokenInterceptor(dio: dio, tokenStorage: this.tokenStorage),
    ]);

    // ── Concurrency Tuning ────────────────────────────────────────────────
    // Increase max connections for the underlying HttpClient
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.maxConnectionsPerHost = 100; // Increase from default of 5
      return client;
    };

    return dio;
  }

  // ── Public HTTP methods ───────────────────────────────────────────────────

  /// GET request. [queryParameters] are URL-encoded.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST request with a JSON body.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// PATCH request — partial update.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// PUT request — full update.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST multipart/form-data — for file uploads.
  Future<Response<T>> postForm<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options ?? Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  // ── Unauthenticated shortcuts (login / register / refresh) ────────────────

  /// Performs a POST without attaching the JWT header.
  ///
  /// Use this for endpoints like login, register, and token refresh.
  Future<Response<T>> postPublic<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: {'X-No-Auth': 'true'}),
    );
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  ApiException _mapException(DioException e) {
    // Already converted by RefreshTokenInterceptor
    if (e.error is ApiException) return e.error as ApiException;

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _mapStatusCode(statusCode, responseData);

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request was cancelled.',
          statusCode: statusCode,
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'SSL certificate error. Connection is not secure.',
        );

      case DioExceptionType.unknown:
        // Wrap dart:io SocketException etc.
        return NetworkException(
          message: e.message ?? 'An unknown network error occurred.',
        );
    }
  }

  ApiException _mapStatusCode(int? code, dynamic data) {
    switch (code) {
      case 400:
        return ValidationException(
          message: _extractDetail(data) ?? 'Validation failed.',
          statusCode: code,
          data: data,
          errors: data is Map<String, dynamic> ? data : null,
        );

      case 401:
        return UnauthorizedException(
          message: _extractDetail(data) ?? 'Authentication required.',
          data: data,
        );

      case 403:
        return ForbiddenException(
          message: _extractDetail(data) ?? 'Forbidden.',
          data: data,
          // DRF can return {"detail":"..","required_role":"admin","current_role":"resident"}
          requiredRole: data is Map ? data['required_role']?.toString() : null,
          currentRole: data is Map ? data['current_role']?.toString() : null,
        );

      case 404:
        return NotFoundException(
          message: _extractDetail(data) ?? 'Not found.',
          data: data,
        );

      case 409:
        return ConflictException(
          message: _extractDetail(data) ?? 'Conflict occurred.',
          data: data,
        );

      case 422:
        return ValidationException(
          message: _extractDetail(data) ?? 'Unprocessable entity.',
          statusCode: code,
          data: data,
          errors: data is Map<String, dynamic> ? data : null,
        );

      case 429:
        return TooManyRequestsException(
          message: _extractDetail(data) ?? 'Too many requests. Please try again later.',
          data: data,
        );

      default:
        if (code != null && code >= 500) {
          return ServerException(
            message: _extractDetail(data) ?? 'Server error ($code).',
            statusCode: code,
            data: data,
          );
        }
        return ServerException(
          message: 'Unexpected error (HTTP $code).',
          statusCode: code,
          data: data,
        );
    }
  }

  /// Extracts the `detail` field that DRF commonly returns in error bodies.
  String? _extractDetail(dynamic data) {
    if (data is Map) return data['detail']?.toString();
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  // ── Accessors ─────────────────────────────────────────────────────────────

  /// Exposes the underlying Dio instance for advanced use (e.g. upload with progress).
  /// Prefer the typed methods above wherever possible.
  Dio get dio => _dio;
}
