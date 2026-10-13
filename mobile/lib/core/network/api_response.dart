class ApiResponse {
  final bool isSuccess;
  final int statusCode;
  final dynamic data;
  final String? errorMessage;

  const ApiResponse({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  /// statusCode 0 means the request never reached the server.
  bool get isNetworkError => statusCode == 0;
}
