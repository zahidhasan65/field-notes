import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/models/auth_user_model.dart';

class SessionStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  Future<void> saveSession({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_tokenKey, token);
    await preferences.setString(_userIdKey, userId);
    await preferences.setString(_userNameKey, userName);
    await preferences.setString(_userEmailKey, userEmail);
  }

  Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getString(_tokenKey);
  }

  Future<AuthUserModel?> getUser() async {
    final preferences = await SharedPreferences.getInstance();

    final id = preferences.getString(_userIdKey);
    final name = preferences.getString(_userNameKey);
    final email = preferences.getString(_userEmailKey);

    if (id == null || name == null || email == null) {
      return null;
    }

    return AuthUserModel(id: id, name: name, email: email);
  }

  Future<bool> hasSession() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_tokenKey);
    await preferences.remove(_userIdKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
  }

  Future<String?> getUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_userIdKey);
  }
}
