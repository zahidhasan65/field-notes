import 'package:equatable/equatable.dart';
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

class SettingsState extends Equatable {
  final NoteStatus defaultStatus;
  const SettingsState({this.defaultStatus = NoteStatus.pending});

  @override
  List<Object?> get props => [defaultStatus];
}

/// "Default Note Status": saved on the device only (not synced), used when a
/// new field note is created, and still there after restarting the app.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this.repository}) : super(const SettingsState()) {
    on<SettingsStarted>((e, emit) async {
      emit(SettingsState(defaultStatus: await repository.getDefaultNoteStatus()));
    });
    on<DefaultNoteStatusChanged>((e, emit) async {
      emit(SettingsState(defaultStatus: e.status));
      await repository.setDefaultNoteStatus(e.status);
    });
    add(const SettingsStarted());
  }

  final AppSettingsRepository repository;
}
