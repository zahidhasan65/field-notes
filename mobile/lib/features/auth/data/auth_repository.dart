import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/local/data_sources/user_local_data_source.dart';
import '../models/auth_user_model.dart';
import '../models/password_reset_result.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository({
    required this.remote,
    required this.session,
    required this.users,
    required this.settings,
  });

  final AuthRemoteDataSource remote;
  final SessionStorage session;
  final UserLocalDataSource users;
  final AppSettingsRepository settings;

  Future<AuthUserModel> login({required String email, required String password}) async {
    final response = await remote.login(email: email, password: password);
    await _saveSession(response.token, response.user);
    return response.user;
  }

  Future<AuthUserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await remote.register(name: name, email: email, password: password);
    await _saveSession(response.token, response.user);
    // a brand new account has nothing on the server to restore
    await settings.setRestoreDone(response.user.id);
    return response.user;
  }

  Future<AuthUserModel> loginWithGoogle(String idToken) async {
    final response = await remote.loginWithGoogle(idToken: idToken);
    await _saveSession(response.token, response.user);
    return response.user;
  }

  Future<AuthUserModel> updateName(String name) async {
    final token = await _requireToken();
    final user = await remote.updateName(token: token, name: name.trim());
    await session.saveSession(
      token: token,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
    );
    await users.upsert(id: user.id, name: user.name, email: user.email);
    return user;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _requireToken();
    await remote.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<String> _requireToken() async {
    final token = await session.getToken();
    if (token == null || token.isEmpty) throw const AuthExpiredException();
    return token;
  }

  Future<PasswordResetResult> requestPasswordReset(String email) =>
      remote.requestPasswordReset(email: email);

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) =>
      remote.resetPassword(email: email, otp: otp, newPassword: newPassword);

  Future<void> _saveSession(String token, AuthUserModel user) async {
    await session.saveSession(
      token: token,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
    );
    await users.upsert(id: user.id, name: user.name, email: user.email);
  }

  Future<AuthUserModel?> currentUser() async {
    if (!await session.hasSession()) return null;
    final user = await session.getUser();
    if (user != null) {
      await users.upsert(id: user.id, name: user.name, email: user.email);
    }
    return user;
  }

  Future<bool> needsRestore(String userId) async => !(await settings.isRestoreDone(userId));

  Future<void> logout() => session.clearSession();
}
