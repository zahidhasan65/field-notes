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
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
    await p.setString(_userIdKey, userId);
    await p.setString(_userNameKey, userName);
    await p.setString(_userEmailKey, userEmail);
  }

  Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  Future<AuthUserModel?> getUser() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_userIdKey);
    final name = p.getString(_userNameKey);
    final email = p.getString(_userEmailKey);
    if (id == null || name == null || email == null) return null;
    return AuthUserModel(id: id, name: name, email: email);
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_userIdKey);
  }

  Future<void> clearSession() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
    await p.remove(_userIdKey);
    await p.remove(_userNameKey);
    await p.remove(_userEmailKey);
  }
}
