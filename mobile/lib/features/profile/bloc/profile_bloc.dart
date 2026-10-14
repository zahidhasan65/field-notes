import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../services/photo_storage.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/models/auth_user_model.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileStarted extends ProfileEvent {
  final String userId;
  const ProfileStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ProfileStopped extends ProfileEvent {
  const ProfileStopped();
}

class ProfilePhotoSelected extends ProfileEvent {
  final String path;
  const ProfilePhotoSelected(this.path);
  @override
  List<Object?> get props => [path];
}

class ProfilePhotoRemoved extends ProfileEvent {
  const ProfilePhotoRemoved();
}

class ProfileNameSubmitted extends ProfileEvent {
  final String name;
  const ProfileNameSubmitted(this.name);
  @override
  List<Object?> get props => [name];
}

class ProfilePasswordSubmitted extends ProfileEvent {
  final String currentPassword;
  final String newPassword;
  const ProfilePasswordSubmitted({required this.currentPassword, required this.newPassword});
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

enum ProfileAction { none, photo, name, password }

class ProfileState extends Equatable {
  final String? photoPath;
  final bool isBusy;

  final ProfileAction action;
  final String? message;
  final String? error;

  final int nonce;

  final AuthUserModel? updatedUser;

  const ProfileState({
    this.photoPath,
    this.isBusy = false,
    this.action = ProfileAction.none,
    this.message,
    this.error,
    this.nonce = 0,
    this.updatedUser,
  });

  @override
  List<Object?> get props =>
      [photoPath, isBusy, action, message, error, nonce, updatedUser?.name];
}


class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this.authRepository,
    required this.settings,
    required this.photos,
    required this.connectivity,
    required this.notifications,
  }) : super(const ProfileState()) {
    on<ProfileStarted>((e, emit) async {
      _userId = e.userId;
      final path = await settings.getProfilePhoto(e.userId);
      emit(ProfileState(photoPath: path));
    });
    on<ProfileStopped>((e, emit) {
      _userId = null;
      emit(const ProfileState());
    });
    on<ProfilePhotoSelected>(_onPhotoSelected);
    on<ProfilePhotoRemoved>(_onPhotoRemoved);
    on<ProfileNameSubmitted>(_onName);
    on<ProfilePasswordSubmitted>(_onPassword);
  }

  final AuthRepository authRepository;
  final AppSettingsRepository settings;
  final PhotoStorage photos;
  final ConnectivityService connectivity;
  final NotificationRepository notifications;

  String? _userId;

  static const _offline = 'Internet connection required. Please connect and try again.';

  Future<void> _onPhotoSelected(ProfilePhotoSelected e, Emitter<ProfileState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    final old = state.photoPath;
    await settings.setProfilePhoto(userId, e.path);
    if (old != null && old != e.path) await photos.delete(old);
    emit(_done(photoPath: e.path, action: ProfileAction.photo, message: 'Profile photo updated'));
  }

  Future<void> _onPhotoRemoved(ProfilePhotoRemoved e, Emitter<ProfileState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    final old = state.photoPath;
    await settings.setProfilePhoto(userId, null);
    await photos.delete(old);
    emit(ProfileState(
      photoPath: null,
      action: ProfileAction.photo,
      message: 'Profile photo removed',
      nonce: state.nonce + 1,
    ));
  }

  Future<void> _onName(ProfileNameSubmitted e, Emitter<ProfileState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    emit(_busy());

    if (!await connectivity.isOnline()) {
      emit(_fail(ProfileAction.name, _offline));
      return;
    }
    try {
      final user = await authRepository.updateName(e.name);
      emit(ProfileState(
        photoPath: state.photoPath,
        action: ProfileAction.name,
        message: 'Name updated',
        nonce: state.nonce + 1,
        updatedUser: user,
      ));
      await notifications.add(userId,
          type: AppNotificationType.success,
          title: 'Profile updated',
          body: 'Your name is now ${user.name}.');
    } on ApiException catch (ex) {
      emit(_fail(ProfileAction.name, ex.message));
    } catch (_) {
      emit(_fail(ProfileAction.name, 'Could not update your name. Please try again.'));
    }
  }

  Future<void> _onPassword(ProfilePasswordSubmitted e, Emitter<ProfileState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    emit(_busy());

    if (!await connectivity.isOnline()) {
      emit(_fail(ProfileAction.password, _offline));
      return;
    }
    try {
      await authRepository.changePassword(
        currentPassword: e.currentPassword,
        newPassword: e.newPassword,
      );
      emit(_done(action: ProfileAction.password, message: 'Password changed'));
      await notifications.add(userId,
          type: AppNotificationType.success,
          title: 'Password changed',
          body: 'Your password was updated. Use it the next time you log in.');
    } on ApiException catch (ex) {
      emit(_fail(ProfileAction.password, ex.message));
    } catch (_) {
      emit(_fail(ProfileAction.password, 'Could not change the password. Please try again.'));
    }
  }

  // ---- state helpers (always build a NEW state from the current values) ----
  ProfileState _busy() => ProfileState(photoPath: state.photoPath, isBusy: true);

  ProfileState _done({String? photoPath, required ProfileAction action, required String message}) =>
      ProfileState(
        photoPath: photoPath ?? state.photoPath,
        action: action,
        message: message,
        nonce: state.nonce + 1,
      );

  ProfileState _fail(ProfileAction action, String error) => ProfileState(
        photoPath: state.photoPath,
        action: action,
        error: error,
        nonce: state.nonce + 1,
      );
}
