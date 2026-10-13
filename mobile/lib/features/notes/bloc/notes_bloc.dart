import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class NotesStarted extends NotesEvent {
  const NotesStarted();
}

class NotesChanged extends NotesEvent {
  const NotesChanged();
}

class NotesQueryChanged extends NotesEvent {
  final String query;
  const NotesQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class NotesStatusFilterChanged extends NotesEvent {
  final NoteStatus? status; // null = all
  const NotesStatusFilterChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class NotesSiteFilterChanged extends NotesEvent {
  final String? siteId; // null = all sites
  const NotesSiteFilterChanged(this.siteId);
  @override
  List<Object?> get props => [siteId];
}

class NotesState extends Equatable {
  final LoadStatus status;
  final List<NoteView> notes;
  final List<SiteView> sites; // for the site filter
  final String query;
  final NoteStatus? statusFilter;
  final String? siteId;
  final String? error;

  const NotesState({
    this.status = LoadStatus.loading,
    this.notes = const [],
    this.sites = const [],
    this.query = '',
    this.statusFilter,
    this.siteId,
    this.error,
  });

  String? get siteName {
    if (siteId == null) return null;
    for (final s in sites) {
      if (s.site.id == siteId) return s.site.siteName;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        status,
        notes.map((n) => '${n.note.id}${n.note.updatedAt}${n.note.syncStatus}${n.note.photoPath}').toList(),
        sites.map((s) => '${s.site.id}${s.site.updatedAt}').toList(),
        query,
        statusFilter,
        siteId,
        error,
      ];
}

/// Field notes with search (title / description / site / customer) and
/// filters (status / site). Everything is queried with SQL JOINs.
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({
    required this.notesRepository,
    required this.sitesRepository,
    required this.userId,
    String? initialSiteId,
  }) : super(NotesState(siteId: initialSiteId)) {
    on<NotesStarted>((e, emit) => _load(emit));
    on<NotesChanged>((e, emit) => _load(emit));
    on<NotesQueryChanged>((e, emit) => _load(emit, query: e.query));
    on<NotesStatusFilterChanged>((e, emit) => _load(emit, status: e.status, setStatus: true));
    on<NotesSiteFilterChanged>((e, emit) => _load(emit, siteId: e.siteId, setSite: true));
    _sub = DataEvents.stream.listen((_) => add(const NotesChanged()));
    add(const NotesStarted());
  }

  final FieldNoteRepository notesRepository;
  final SiteRepository sitesRepository;
  final String userId;
  StreamSubscription<void>? _sub;

  Future<void> _load(
    Emitter<NotesState> emit, {
    String? query,
    NoteStatus? status,
    bool setStatus = false,
    String? siteId,
    bool setSite = false,
  }) async {
    final q = query ?? state.query;
    final st = setStatus ? status : state.statusFilter;
    final site = setSite ? siteId : state.siteId;

    try {
      final notes = await notesRepository.search(userId, query: q, status: st, siteId: site);
      final sites = await sitesRepository.list(userId);
      emit(NotesState(
        status: LoadStatus.loaded,
        notes: notes,
        sites: sites,
        query: q,
        statusFilter: st,
        siteId: site,
      ));
    } catch (e) {
      emit(NotesState(
        status: LoadStatus.failure,
        query: q,
        statusFilter: st,
        siteId: site,
        error: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
