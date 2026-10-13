import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

class NoteSubmitted extends Equatable {
  final NoteDraft draft;
  const NoteSubmitted(this.draft);
  @override
  List<Object?> get props => [draft.siteId, draft.title, draft.description, draft.status, draft.noteDatetime, draft.photoPath];
}

class NoteFormBloc extends Bloc<NoteSubmitted, SubmitState> {
  NoteFormBloc({
    required this.repository,
    required this.userId,
    this.existing,
  }) : super(const SubmitState()) {
    on<NoteSubmitted>((event, emit) async {
      emit(const SubmitState(status: SubmitStatus.saving));
      try {
        if (existing == null) {
          await repository.create(userId, event.draft);
        } else {
          await repository.update(userId, existing!, event.draft);
        }
        emit(const SubmitState(status: SubmitStatus.success));
      } catch (_) {
        emit(const SubmitState(
            status: SubmitStatus.failure, error: 'Could not save the note.'));
      }
    });
  }

  final FieldNoteRepository repository;
  final String userId;
  final FieldNoteLocal? existing;
}
