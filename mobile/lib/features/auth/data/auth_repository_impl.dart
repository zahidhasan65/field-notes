import '../../../core/storage/session_storage.dart';
import '../models/auth_response_model.dart';
import '../models/auth_user_model.dart';
import '../repositories/auth_repository.dart';
import 'remote/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SessionStorage sessionStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionStorage,
  });

  @override
  Future<AuthUserModel?> checkAuthentication() async {
    final token = await sessionStorage.getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    return sessionStorage.getUser();
  }

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    final AuthResponseModel response = await remoteDataSource.login(
      email: email,
      password: password,
    );

    await sessionStorage.saveSession(
      token: response.token,
      userId: response.user.id,
      userName: response.user.name,
      userEmail: response.user.email,
    );

    return response.user;
  }

  @override
  Future<AuthUserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final AuthResponseModel response = await remoteDataSource.register(
      name: name,
      email: email,
      password: password,
    );

    await sessionStorage.saveSession(
      token: response.token,
      userId: response.user.id,
      userName: response.user.name,
      userEmail: response.user.email,
    );

    return response.user;
  }

  @override
  Future<void> logout() async {
    await sessionStorage.clearSession();
  }
}
