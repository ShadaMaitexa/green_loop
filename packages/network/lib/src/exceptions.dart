/// Typed exceptions produced by the GreenLoop API client.
///
/// All app code should catch these instead of raw DioException so that
/// error handling is isolated to one place.

/// Base class — all GreenLoop network errors extend this.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException[$statusCode]: $message';
}

// ── 4xx Client errors ─────────────────────────────────────────────────────

/// 401 — Token missing, expired, or invalid.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Authentication required. Please log in again.',
    super.statusCode = 401,
    super.data,
  });
}

/// 403 — User authenticated but lacks the required role/permission.
class ForbiddenException extends ApiException {
  /// The role the server reported is required for this resource.
  final String? requiredRole;

  /// The role the current user actually holds.
  final String? currentRole;

  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode = 403,
    super.data,
    this.requiredRole,
    this.currentRole,
  });

  @override
  String toString() =>
      'ForbiddenException[403]: $message '
      '(currentRole=$currentRole, requiredRole=$requiredRole)';
}

/// 404 — Resource not found.
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.data,
  });
}

/// 409 — Resource conflict (e.g. slot already booked).
class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'The requested slot is no longer available.',
    super.statusCode = 409,
    super.data,
  });
}

/// 429 — Rate limit exceeded.
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({
    super.message = 'Too many requests. Please try again later.',
    super.statusCode = 429,
    super.data,
  });
}

/// 422 / 400 — Validation error from DRF.
class ValidationException extends ApiException {
  /// Field-level errors as returned by DRF, e.g. {"email": ["Enter a valid email."]}.
  final Map<String, dynamic>? errors;

  const ValidationException({
    super.message = 'Validation failed.',
    super.statusCode,
    super.data,
    this.errors,
  });
}

// ── 5xx Server errors ─────────────────────────────────────────────────────

/// 5xx — Django returned an unexpected server error.
class ServerException extends ApiException {
  const ServerException({
    super.message = 'An unexpected server error occurred. Please try later.',
    super.statusCode,
    super.data,
  });
}

// ── Network / connection errors ───────────────────────────────────────────

/// No internet, DNS failure, connection refused, timeout, etc.
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Unable to reach the server. Check your internet connection.',
    super.statusCode,
    super.data,
  });
}

/// Used when the app receives a response with an unexpected format.
class ParseException extends ApiException {
  const ParseException({
    super.message = 'Failed to parse the server response.',
    super.statusCode,
    super.data,
  });
}
