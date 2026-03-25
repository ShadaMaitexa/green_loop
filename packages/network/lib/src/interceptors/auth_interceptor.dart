import 'package:dio/dio.dart';
import '../token_storage.dart';

/// Attaches the JWT `Authorization: Bearer <token>` header to every outgoing
/// request that does NOT carry one already.
///
/// Endpoints that explicitly skip auth (e.g. login, register) can set the
/// custom header `X-No-Auth: true` on their [RequestOptions] to bypass
/// this interceptor.
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  static const _skipHeader = 'X-No-Auth';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip endpoints that explicitly opt out of auth
    if (options.headers.containsKey(_skipHeader)) {
      options.headers.remove(_skipHeader);
      return handler.next(options);
    }

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }
}
