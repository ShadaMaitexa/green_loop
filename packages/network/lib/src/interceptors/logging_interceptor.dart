import 'package:dio/dio.dart';

/// Pretty-prints all HTTP requests and responses in [debug] mode only.
///
/// In release builds the interceptor is a no-op so no sensitive data
/// leaks into device logs.
class LoggingInterceptor extends Interceptor {
  final bool debug;
  final void Function(String)? logger;

  const LoggingInterceptor({this.debug = true, this.logger});

  void _log(String msg) {
    if (!debug) return;
    if (logger != null) {
      logger!(msg);
    } else {
      // ignore: avoid_print
      print(msg);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log(
      '\n🌐 REQUEST ──────────────────────────────────────\n'
      '  ${options.method} ${options.uri}\n'
      '  Headers: ${_sanitiseHeaders(options.headers)}\n'
      '  Body:    ${options.data}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(
      '\n✅ RESPONSE ─────────────────────────────────────\n'
      '  ${response.statusCode} ${response.requestOptions.uri}\n'
      '  Data: ${response.data}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '\n❌ ERROR ────────────────────────────────────────\n'
      '  ${err.response?.statusCode} ${err.requestOptions.uri}\n'
      '  Message: ${err.message}\n'
      '  Response: ${err.response?.data}',
    );
    handler.next(err);
  }

  /// Replace the Authorization value with [REDACTED] so tokens don't appear in logs.
  Map<String, dynamic> _sanitiseHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = '[REDACTED]';
    }
    return copy;
  }
}
