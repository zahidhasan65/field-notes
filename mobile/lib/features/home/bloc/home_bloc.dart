import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class HomeChanged extends HomeEvent {
  const HomeChanged();
}

class HomeState extends Equatable {
  final LoadStatus status;
  final int noteCount;
  final int customerCount;
  final int siteCount;
  final List<NoteView> recent;

  const HomeState({
    this.status = LoadStatus.loading,
    this.noteCount = 0,
    this.customerCount = 0,
    this.siteCount = 0,
    this.recent = const [],
  });

  @override
  List<Object?> get props => [
        status,
        noteCount,
        customerCount,
        siteCount,
        recent.map((n) => '${n.note.id}${n.note.updatedAt}${n.note.syncStatus}${n.note.photoPath}').toList(),
      ];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this.userId,
    required this.customers,
    required this.sites,
    required this.notes,
  }) : super(const HomeState()) {
    on<HomeStarted>((e, emit) => _load(emit));
    on<HomeChanged>((e, emit) => _load(emit));
    _sub = DataEvents.stream.listen((_) => add(const HomeChanged()));
    add(const HomeStarted());
  }

  final String userId;
  final CustomerRepository customers;
  final SiteRepository sites;
  final FieldNoteRepository notes;
  StreamSubscription<void>? _sub;

  Future<void> _load(Emitter<HomeState> emit) async {
    try {
      emit(HomeState(
        status: LoadStatus.loaded,
        customerCount: await customers.count(userId),
        siteCount: await sites.count(userId),
        noteCount: await notes.count(userId),
        recent: await notes.search(userId, limit: 3),
      ));
    } catch (_) {
      emit(const HomeState(status: LoadStatus.failure));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
