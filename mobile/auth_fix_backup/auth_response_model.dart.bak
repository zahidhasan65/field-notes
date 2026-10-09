import 'auth_user_model.dart';

class AuthResponseModel {
  final String token;
  final AuthUserModel user;

  const AuthResponseModel({required this.token, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
