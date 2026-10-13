import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class SitesEvent extends Equatable {
  const SitesEvent();
  @override
  List<Object?> get props => [];
}

class SitesStarted extends SitesEvent {
  const SitesStarted();
}

class SitesChanged extends SitesEvent {
  const SitesChanged();
}

class SitesQueryChanged extends SitesEvent {
  final String query;
  const SitesQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class SiteDeleteRequested extends SitesEvent {
  final SiteLocal site;
  const SiteDeleteRequested(this.site);
  @override
  List<Object?> get props => [site.id];
}

class SitesState extends Equatable {
  final LoadStatus status;
  final List<SiteView> sites;
  final String query;
  final String? error;

  const SitesState({
    this.status = LoadStatus.loading,
    this.sites = const [],
    this.query = '',
    this.error,
  });

  @override
  List<Object?> get props => [
        status,
        sites.map((s) => '${s.site.id}${s.site.updatedAt}${s.site.syncStatus}${s.noteCount}').toList(),
        query,
        error,
      ];
}

/// Sites of the user, optionally only those of one customer.
class SitesBloc extends Bloc<SitesEvent, SitesState> {
  SitesBloc({
    required this.repository,
    required this.userId,
    this.customerId,
  }) : super(const SitesState()) {
    on<SitesStarted>((e, emit) => _load(emit, query: state.query));
    on<SitesChanged>((e, emit) => _load(emit, query: state.query));
    on<SitesQueryChanged>((e, emit) => _load(emit, query: e.query));
    on<SiteDeleteRequested>((e, emit) async {
      await repository.delete(userId, e.site);
    });
    _sub = DataEvents.stream.listen((_) => add(const SitesChanged()));
    add(const SitesStarted());
  }

  final SiteRepository repository;
  final String userId;
  final String? customerId;
  StreamSubscription<void>? _sub;

  Future<void> _load(Emitter<SitesState> emit, {required String query}) async {
    try {
      final list = await repository.list(userId, customerId: customerId, query: query);
      emit(SitesState(status: LoadStatus.loaded, sites: list, query: query));
    } catch (e) {
      emit(SitesState(status: LoadStatus.failure, query: query, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
