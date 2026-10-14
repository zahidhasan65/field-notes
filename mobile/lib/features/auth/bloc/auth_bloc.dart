import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../services/google_auth_service.dart';
import '../data/auth_repository.dart';
import '../models/auth_user_model.dart';

// ---------------- events ----------------
sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, password];
}

class AuthUserUpdated extends AuthEvent {
  final AuthUserModel user;
  const AuthUserUpdated(this.user);
  @override
  List<Object?> get props => [user.id, user.name, user.email];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

// Screen change korar somoy purono error muche felar jonno
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

// ---------------- states ----------------
sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUserModel user;

  final bool needsRestore;
  const AuthAuthenticated({required this.user, required this.needsRestore});
  @override
  List<Object?> get props => [user.id, user.name, user.email, needsRestore];
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated({this.message});
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ---------------- bloc ----------------
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.repository,
    required this.connectivity,
    required this.google,
  }) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUserUpdated>((event, emit) {
      if (state is AuthAuthenticated) {
        emit(AuthAuthenticated(user: event.user, needsRestore: false));
      }
    });
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthErrorCleared>((event, emit) {
      if (state is AuthFailure) emit(const AuthUnauthenticated());
    });
  }

  final AuthRepository repository;
  final ConnectivityService connectivity;
  final GoogleAuthService google;

  static const _offlineLogin =
      'Internet connection required to log in. Please connect and try again.';
  static const _offlineRegister =
      'Internet connection required to create an account. Please connect and try again.';

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = await repository.currentUser();
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(AuthAuthenticated(
      user: user,
      needsRestore: await repository.needsRestore(user.id),
    ));
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    if (!await connectivity.isOnline()) {
      emit(const AuthFailure(_offlineLogin));
      return;
    }
    try {
      final user = await repository.login(email: event.email, password: event.password);
      emit(AuthAuthenticated(
        user: user,
        needsRestore: await repository.needsRestore(user.id),
      ));
    } on ApiException catch (e) {
      emit(AuthFailure(e.statusCode == 401 ? 'Invalid email or password.' : e.message));
    } catch (_) {
      emit(const AuthFailure('Login failed. Please try again.'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    if (!await connectivity.isOnline()) {
      emit(const AuthFailure(_offlineRegister));
      return;
    }
    try {
      final user = await repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user, needsRestore: false));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('Registration failed. Please try again.'));
    }
  }

  Future<void> _onGoogleLogin(
      AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    if (!google.isConfigured) {
      emit(const AuthFailure(
          'Google sign-in is not configured yet. Run the app with GOOGLE_SERVER_CLIENT_ID (see GOOGLE_SETUP.md).'));
      return;
    }

    emit(const AuthLoading());
    if (!await connectivity.isOnline()) {
      emit(const AuthFailure(_offlineLogin));
      return;
    }

    try {
      final idToken = await google.signInAndGetIdToken();
      if (idToken == null) {
        emit(const AuthUnauthenticated()); // the user closed the account picker
        return;
      }
      final user = await repository.loginWithGoogle(idToken);
      emit(AuthAuthenticated(
        user: user,
        needsRestore: await repository.needsRestore(user.id),
      ));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } on PlatformException catch (e) {
      emit(AuthFailure(google.friendlyError(e)));
    } catch (_) {
      emit(const AuthFailure('Google sign-in failed. Please try again.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    await google.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionExpired(AuthSessionExpired event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(const AuthUnauthenticated(message: 'Your session expired. Please log in again.'));
  }
}