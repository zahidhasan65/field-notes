import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/data.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class DefaultNoteStatusChanged extends SettingsEvent {
  final NoteStatus status;
  const DefaultNoteStatusChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class ThemeModeChanged extends SettingsEvent {
  final ThemeMode mode;
  const ThemeModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class NotifySyncChanged extends SettingsEvent {
  final bool enabled;
  const NotifySyncChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class NotifyOfflineChanged extends SettingsEvent {
  final bool enabled;
  const NotifyOfflineChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsState extends Equatable {
  final NoteStatus defaultStatus;
  final ThemeMode themeMode;
  final bool notifySync;
  final bool notifyOffline;

  const SettingsState({
    this.defaultStatus = NoteStatus.pending,
    this.themeMode = ThemeMode.system,
    this.notifySync = true,
    this.notifyOffline = true,
  });

  SettingsState copyWith({
    NoteStatus? defaultStatus,
    ThemeMode? themeMode,
    bool? notifySync,
    bool? notifyOffline,
  }) =>
      SettingsState(
        defaultStatus: defaultStatus ?? this.defaultStatus,
        themeMode: themeMode ?? this.themeMode,
        notifySync: notifySync ?? this.notifySync,
        notifyOffline: notifyOffline ?? this.notifyOffline,
      );

  @override
  List<Object?> get props => [defaultStatus, themeMode, notifySync, notifyOffline];
}


class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this.repository}) : super(const SettingsState()) {
    on<SettingsStarted>((e, emit) async {
      final status = await repository.getDefaultNoteStatus();
      final mode = await repository.getThemeMode();
      final sync = await repository.getNotifySync();
      final offline = await repository.getNotifyOffline();
      emit(SettingsState(
        defaultStatus: status,
        themeMode: mode,
        notifySync: sync,
        notifyOffline: offline,
      ));
    });
    on<DefaultNoteStatusChanged>((e, emit) async {
      emit(state.copyWith(defaultStatus: e.status));
      await repository.setDefaultNoteStatus(e.status);
    });
    on<ThemeModeChanged>((e, emit) async {
      emit(state.copyWith(themeMode: e.mode));
      await repository.setThemeMode(e.mode);
    });
    on<NotifySyncChanged>((e, emit) async {
      emit(state.copyWith(notifySync: e.enabled));
      await repository.setNotifySync(e.enabled);
    });
    on<NotifyOfflineChanged>((e, emit) async {
      emit(state.copyWith(notifyOffline: e.enabled));
      await repository.setNotifyOffline(e.enabled);
    });
    add(const SettingsStarted());
  }

  final AppSettingsRepository repository;
}
