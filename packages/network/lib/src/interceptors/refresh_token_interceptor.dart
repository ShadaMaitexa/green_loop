import 'dart:async';

import 'package:dio/dio.dart';
import '../token_storage.dart';
import '../exceptions.dart';

/// Handles expired access tokens transparently:
///
/// 1. Intercepts every 401 response.
/// 2. Calls `POST /api/auth/token/refresh/` with the stored refresh token.
/// 3. Saves the new access (and optional refresh) token.
/// 4. Retries the original request with the new token.
/// 5. If the refresh itself fails, clears all tokens and throws [UnauthorizedException].
///
/// A [_Lock] prevents concurrent refresh attempts: the first 401 triggers the
/// refresh; subsequent requests queued during that refresh are held and then
/// replayed once the new token is available.
class RefreshTokenInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final String _refreshPath;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingQueue = [];

  RefreshTokenInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    String refreshPath = '/api/v1/auth/token/refresh/',
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _refreshPath = refreshPath;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401
    if (err.response?.statusCode != 401) return handler.next(err);

    // Avoid infinite loop if the refresh call itself returns 401
    if (err.requestOptions.path.contains(_refreshPath)) {
      await _tokenStorage.clearAll();
      return handler.reject(
        err.copyWith(
          error: const UnauthorizedException(
            message: 'Session expired. Please log in again.',
          ),
        ),
      );
    }

    final requestOptions = err.requestOptions;

    if (_isRefreshing) {
      // Queue this request until the ongoing refresh completes
      final pending = _PendingRequest(options: requestOptions);
      _pendingQueue.add(pending);
      try {
        final response = await pending.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const UnauthorizedException();
      }

      // Call the DRF SimpleJWT refresh endpoint
      final refreshResponse = await _dio.post(
        _refreshPath,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'X-No-Auth': 'true'}, // skip AuthInterceptor
        ),
      );

      final newAccess = refreshResponse.data['access'] as String?;
      final newRefresh = refreshResponse.data['refresh'] as String?;

      if (newAccess == null) throw const UnauthorizedException();

      await _tokenStorage.saveAccessToken(newAccess);
      if (newRefresh != null) await _tokenStorage.saveRefreshToken(newRefresh);

      // Retry original request with updated token
      final retried = await _retry(requestOptions, newAccess);

      // Resolve all queued requests
      for (final pending in _pendingQueue) {
        try {
          final r = await _retry(pending.options, newAccess);
          pending.complete(r);
        } catch (e) {
          pending.completeError(e);
        }
      }

      return handler.resolve(retried);
    } catch (_) {
      await _tokenStorage.clearAll();
      for (final pending in _pendingQueue) {
        pending.completeError(const UnauthorizedException());
      }
      return handler.reject(
        DioException(
          requestOptions: requestOptions,
          error: const UnauthorizedException(),
        ),
      );
    } finally {
      _isRefreshing = false;
      _pendingQueue.clear();
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions options,
    String accessToken,
  ) {
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {
          ...options.headers,
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }
}

// ── Internal queue helper ─────────────────────────────────────────────────

class _PendingRequest {
  final RequestOptions options;
  late final Future<Response<dynamic>> future;

  final Completer<Response<dynamic>> _completer =
      Completer<Response<dynamic>>();

  _PendingRequest({required this.options}) {
    future = _completer.future;
  }

  void complete(Response<dynamic> response) => _completer.complete(response);
  void completeError(Object error) => _completer.completeError(error);
}
