

class PasswordResetResult {
  final String message;
  final String? devOtp;

  const PasswordResetResult({required this.message, this.devOtp});

  factory PasswordResetResult.fromJson(Map<String, dynamic> json) =>
      PasswordResetResult(
        message: (json['message'] ?? '').toString(),
        devOtp: json['devOtp'] as String?,
      );
}
