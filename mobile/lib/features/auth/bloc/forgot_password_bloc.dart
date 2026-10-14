import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../data/auth_repository.dart';

// ---------------- events ----------------
sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();
  @override
  List<Object?> get props => [];
}

class ForgotPasswordOtpRequested extends ForgotPasswordEvent {
  final String email;
  const ForgotPasswordOtpRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class ForgotPasswordResetSubmitted extends ForgotPasswordEvent {
  final String otp;
  final String newPassword;
  const ForgotPasswordResetSubmitted({required this.otp, required this.newPassword});
  @override
  List<Object?> get props => [otp, newPassword];
}

class ForgotPasswordEmailEditRequested extends ForgotPasswordEvent {
  const ForgotPasswordEmailEditRequested();
}

// ---------------- state ----------------
enum ForgotStep { email, otp }

class ForgotPasswordState extends Equatable {
  final ForgotStep step;
  final bool isLoading;
  final String email;
  final String? error;

  final String? devOtp;

  final int otpNonce;
  final bool resetDone;

  const ForgotPasswordState({
    this.step = ForgotStep.email,
    this.isLoading = false,
    this.email = '',
    this.error,
    this.devOtp,
    this.otpNonce = 0,
    this.resetDone = false,
  });

  ForgotPasswordState copyWith({
    ForgotStep? step,
    bool? isLoading,
    String? email,
    String? error,
    bool clearError = false,
    String? devOtp,
    bool clearDevOtp = false,
    int? otpNonce,
    bool? resetDone,
  }) =>
      ForgotPasswordState(
        step: step ?? this.step,
        isLoading: isLoading ?? this.isLoading,
        email: email ?? this.email,
        error: clearError ? null : (error ?? this.error),
        devOtp: clearDevOtp ? null : (devOtp ?? this.devOtp),
        otpNonce: otpNonce ?? this.otpNonce,
        resetDone: resetDone ?? this.resetDone,
      );

  @override
  List<Object?> get props => [step, isLoading, email, error, devOtp, otpNonce, resetDone];
}

// ---------------- bloc ----------------
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({
    required this.repository,
    required this.connectivity,
    String? initialEmail,
  }) : super(ForgotPasswordState(email: initialEmail ?? '')) {
    on<ForgotPasswordOtpRequested>(_onOtpRequested);
    on<ForgotPasswordResetSubmitted>(_onReset);
    on<ForgotPasswordEmailEditRequested>((e, emit) => emit(
          state.copyWith(step: ForgotStep.email, clearError: true, clearDevOtp: true),
        ));
  }

  final AuthRepository repository;
  final ConnectivityService connectivity;

  static const _offline = 'Internet connection required. Please connect and try again.';

  Future<void> _onOtpRequested(
      ForgotPasswordOtpRequested event, Emitter<ForgotPasswordState> emit) async {
    final email = event.email.trim();
    emit(state.copyWith(isLoading: true, email: email, clearError: true));

    if (!await connectivity.isOnline()) {
      emit(state.copyWith(isLoading: false, error: _offline));
      return;
    }

    try {
      final result = await repository.requestPasswordReset(email);
      emit(state.copyWith(
        isLoading: false,
        step: ForgotStep.otp,
        devOtp: result.devOtp,
        clearDevOtp: result.devOtp == null,
        otpNonce: state.otpNonce + 1,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Could not send the OTP. Please try again.'));
    }
  }

  Future<void> _onReset(
      ForgotPasswordResetSubmitted event, Emitter<ForgotPasswordState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    if (!await connectivity.isOnline()) {
      emit(state.copyWith(isLoading: false, error: _offline));
      return;
    }

    try {
      await repository.resetPassword(
        email: state.email,
        otp: event.otp.trim(),
        newPassword: event.newPassword,
      );
      emit(state.copyWith(isLoading: false, resetDone: true));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Could not reset the password. Please try again.'));
    }
  }
}
