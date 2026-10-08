import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../models/auth_response_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiService apiService;

  AuthRemoteDataSourceImpl({
    required this.apiService,
  });

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiService.post(
      endpoint: ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (!response.isSuccess) {
      throw Exception(
        response.errorMessage ?? 'Login failed.',
      );
    }

    return AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiService.post(
      endpoint: ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    if (!response.isSuccess) {
      throw Exception(
        response.errorMessage ?? 'Registration failed.',
      );
    }

    return AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
