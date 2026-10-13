class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.statusCode = 0,
    super.message = 'Cannot reach the server. Check your internet connection.',
  ]);
}

class AuthExpiredException extends ApiException {
  const AuthExpiredException([
    super.statusCode = 401,
    super.message = 'Your session has expired. Please log in again.',
  ]);
}
