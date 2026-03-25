/// Exceptions thrown by the `auth` package components.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([super.message = 'Invalid email or password.']);
}

class AccountDisabledException extends AuthException {
  const AccountDisabledException([super.message = 'This account has been disabled.']);
}

class NotAuthenticatedException extends AuthException {
  const NotAuthenticatedException([super.message = 'No active session found.']);
}
