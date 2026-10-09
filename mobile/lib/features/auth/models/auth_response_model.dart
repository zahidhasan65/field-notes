import 'auth_user_model.dart';

class AuthResponseModel {
  final String token;
  final AuthUserModel user;

  const AuthResponseModel({required this.token, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawToken = json['accessToken'] ?? json['token'];
    final rawUser = json['user'];

    if (rawToken is! String || rawToken.isEmpty) {
      throw const FormatException(
        'Authentication response is missing accessToken.',
      );
    }

    if (rawUser is! Map) {
      throw const FormatException(
        'Authentication response is missing user information.',
      );
    }

    return AuthResponseModel(
      token: rawToken,
      user: AuthUserModel.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }
}
