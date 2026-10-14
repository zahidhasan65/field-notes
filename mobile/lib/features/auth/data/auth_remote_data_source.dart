import '../../../core/core.dart';
import '../models/auth_response_model.dart';
import '../models/auth_user_model.dart';
import '../models/password_reset_result.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({required String email, required String password});

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResponseModel> loginWithGoogle({required String idToken});

  Future<PasswordResetResult> requestPasswordReset({required String email});

  Future<AuthUserModel> updateName({required String token, required String name});

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  });

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final r = await apiService.post(
      endpoint: ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    return _parseAuth(r, 'Login failed.');
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final r = await apiService.post(
      endpoint: ApiConstants.register,
      body: {'name': name, 'email': email, 'password': password},
    );
    return _parseAuth(r, 'Registration failed.');
  }

  @override
  Future<AuthResponseModel> loginWithGoogle({required String idToken}) async {
    final r = await apiService.post(
      endpoint: ApiConstants.googleLogin,
      body: {'idToken': idToken},
    );
    return _parseAuth(r, 'Google sign-in failed.');
  }

  @override
  Future<PasswordResetResult> requestPasswordReset({required String email}) async {
    final r = await apiService.post(
      endpoint: ApiConstants.forgotPassword,
      body: {'email': email},
    );
    _check(r, 'Could not send the OTP.');
    return PasswordResetResult.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final r = await apiService.post(
      endpoint: ApiConstants.resetPassword,
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
    _check(r, 'Could not reset the password.');
  }

  @override
  Future<AuthUserModel> updateName({required String token, required String name}) async {
    final r = await apiService.put(
      endpoint: ApiConstants.me,
      body: {'name': name},
      token: token,
    );
    _check(r, 'Could not update your name.', authenticated: true);
    return AuthUserModel.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final r = await apiService.post(
      endpoint: ApiConstants.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      token: token,
    );
    _check(r, 'Could not change the password.', authenticated: true);
  }

  void _check(ApiResponse r, String fallback, {bool authenticated = false}) {
    if (r.isNetworkError) throw const NetworkException();
    if (authenticated && (r.statusCode == 401 || r.statusCode == 403)) {
      throw const AuthExpiredException();
    }
    if (!r.isSuccess) {
      throw ApiException(r.statusCode, r.errorMessage ?? fallback);
    }
  }

  AuthResponseModel _parseAuth(ApiResponse r, String fallback) {
    _check(r, fallback);
    return AuthResponseModel.fromJson(r.data as Map<String, dynamic>);
  }
}
