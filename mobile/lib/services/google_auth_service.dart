import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';





class GoogleAuthService {
  static const String serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  bool get isConfigured => serverClientId.isNotEmpty;

  late final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: serverClientId.isEmpty ? null : serverClientId,
  );

  Future<String?> signInAndGetIdToken() async {
    // always show the account picker
    await _safeSignOut();

    final account = await _google.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw PlatformException(
        code: 'no_id_token',
        message: 'Google did not return an ID token.',
      );
    }
    return idToken;
  }

  Future<void> signOut() => _safeSignOut();

  Future<void> _safeSignOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // not signed in / plugin not ready: nothing to do
    }
  }

  String friendlyError(PlatformException e) {
    final text = '${e.code} ${e.message}';
    if (text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
      return 'Google sign-in is not set up correctly (package name / SHA-1 / client id). See GOOGLE_SETUP.md.';
    }
    if (text.contains('network_error') || text.contains('ApiException: 7')) {
      return 'Cannot reach Google. Check your internet connection.';
    }
    if (text.contains('no_id_token')) {
      return 'Google did not return an ID token. Check GOOGLE_SERVER_CLIENT_ID.';
    }
    return 'Google sign-in failed. Please try again.';
  }
}
