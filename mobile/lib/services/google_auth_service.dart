import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// "Continue with Google". Gets a Google ID token which the backend verifies.
///
/// Needs the *Web application* OAuth client id of your Google Cloud project:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
/// (the same value as GOOGLE_CLIENT_ID on the backend). See GOOGLE_SETUP.md.
class GoogleAuthService {
  static const String serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  bool get isConfigured => serverClientId.isNotEmpty;

  late final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: serverClientId.isEmpty ? null : serverClientId,
  );

  /// null when the user closed the account picker.
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

  /// Turns the cryptic Google error codes into something the user can act on.
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
