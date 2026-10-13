import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class CustomerDetailEvent extends Equatable {
  const CustomerDetailEvent();
  @override
  List<Object?> get props => [];
}

class CustomerDetailStarted extends CustomerDetailEvent {
  const CustomerDetailStarted();
}

class CustomerDetailChanged extends CustomerDetailEvent {
  const CustomerDetailChanged();
}

class CustomerDeleteRequested extends CustomerDetailEvent {
  const CustomerDeleteRequested();
}

class CustomerDetailState extends Equatable {
  final LoadStatus status;
  final CustomerView? view;
  final List<SiteView> sites;
  final bool deleted;

  const CustomerDetailState({
    this.status = LoadStatus.loading,
    this.view,
    this.sites = const [],
    this.deleted = false,
  });

  @override
  List<Object?> get props => [
        status,
        view?.customer.id,
        view?.customer.updatedAt,
        view?.customer.syncStatus,
        view?.siteCount,
        view?.noteCount,
        sites.map((s) => '${s.site.id}${s.site.updatedAt}${s.site.syncStatus}${s.noteCount}').toList(),
        deleted,
      ];
}

class CustomerDetailBloc extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  CustomerDetailBloc({
    required this.customerId,
    required this.userId,
    required this.customers,
    required this.sitesRepository,
  }) : super(const CustomerDetailState()) {
    on<CustomerDetailStarted>((e, emit) => _load(emit));
    on<CustomerDetailChanged>((e, emit) => _load(emit));
    on<CustomerDeleteRequested>(_onDelete);
    _sub = DataEvents.stream.listen((_) => add(const CustomerDetailChanged()));
    add(const CustomerDetailStarted());
  }

  final String customerId;
  final String userId;
  final CustomerRepository customers;
  final SiteRepository sitesRepository;
  StreamSubscription<void>? _sub;

  Future<void> _load(Emitter<CustomerDetailState> emit) async {
    if (state.deleted) return;
    try {
      final view = await customers.getView(customerId);
      if (view == null) {
        emit(const CustomerDetailState(status: LoadStatus.loaded, deleted: true));
        return;
      }
      final sites = await sitesRepository.list(userId, customerId: customerId);
      emit(CustomerDetailState(status: LoadStatus.loaded, view: view, sites: sites));
    } catch (_) {
      emit(const CustomerDetailState(status: LoadStatus.failure));
    }
  }

  Future<void> _onDelete(CustomerDeleteRequested e, Emitter<CustomerDetailState> emit) async {
    final view = state.view;
    if (view == null) return;
    await customers.delete(view.customer);
    emit(const CustomerDetailState(status: LoadStatus.loaded, deleted: true));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
