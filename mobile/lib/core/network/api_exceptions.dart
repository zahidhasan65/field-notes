class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// The server could not be reached (offline, timeout, DNS ...).
class NetworkException extends ApiException {
  const NetworkException([
    super.statusCode = 0,
    super.message = 'Cannot reach the server. Check your internet connection.',
  ]);
}

/// 401 on an authenticated request: the token is missing or expired.
class AuthExpiredException extends ApiException {
  const AuthExpiredException([
    super.statusCode = 401,
    super.message = 'Your session has expired. Please log in again.',
  ]);
}
