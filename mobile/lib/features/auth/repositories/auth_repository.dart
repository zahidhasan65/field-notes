import '../models/auth_user_model.dart';

abstract class AuthRepository {
  Future<AuthUserModel?> checkAuthentication();

  Future<AuthUserModel> login({
    required String email,
    required String password,
  });

  Future<AuthUserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> logout();
}
