import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class NoteDetailEvent extends Equatable {
  const NoteDetailEvent();
  @override
  List<Object?> get props => [];
}

class NoteDetailStarted extends NoteDetailEvent {
  const NoteDetailStarted();
}

class NoteDetailChanged extends NoteDetailEvent {
  const NoteDetailChanged();
}

class NoteDeleteRequested extends NoteDetailEvent {
  const NoteDeleteRequested();
}

class NoteDetailState extends Equatable {
  final LoadStatus status;
  final NoteView? view;
  final bool deleted;

  const NoteDetailState({
    this.status = LoadStatus.loading,
    this.view,
    this.deleted = false,
  });

  @override
  List<Object?> get props =>
      [status, view?.note.id, view?.note.updatedAt, view?.note.syncStatus, view?.note.photoPath, deleted];
}

class NoteDetailBloc extends Bloc<NoteDetailEvent, NoteDetailState> {
  NoteDetailBloc({
    required this.noteId,
    required this.userId,
    required this.repository,
  }) : super(const NoteDetailState()) {
    on<NoteDetailStarted>((e, emit) => _load(emit));
    on<NoteDetailChanged>((e, emit) => _load(emit));
    on<NoteDeleteRequested>((e, emit) async {
      final view = state.view;
      if (view == null) return;
      await repository.delete(userId, view.note);
      emit(const NoteDetailState(status: LoadStatus.loaded, deleted: true));
    });
    _sub = DataEvents.stream.listen((_) => add(const NoteDetailChanged()));
    add(const NoteDetailStarted());
  }

  final String noteId;
  final String userId;
  final FieldNoteRepository repository;
  StreamSubscription<void>? _sub;

  Future<void> _load(Emitter<NoteDetailState> emit) async {
    if (state.deleted) return;
    try {
      final view = await repository.getView(noteId);
      emit(view == null
          ? const NoteDetailState(status: LoadStatus.loaded, deleted: true)
          : NoteDetailState(status: LoadStatus.loaded, view: view));
    } catch (_) {
      emit(const NoteDetailState(status: LoadStatus.failure));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
