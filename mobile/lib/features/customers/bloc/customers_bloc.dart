import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class CustomersEvent extends Equatable {
  const CustomersEvent();
  @override
  List<Object?> get props => [];
}

class CustomersStarted extends CustomersEvent {
  const CustomersStarted();
}

class CustomersQueryChanged extends CustomersEvent {
  final String query;
  const CustomersQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// The database changed (local edit or sync).
class CustomersChanged extends CustomersEvent {
  const CustomersChanged();
}

class CustomersState extends Equatable {
  final LoadStatus status;
  final List<CustomerView> customers;
  final String query;
  final String? error;

  const CustomersState({
    this.status = LoadStatus.loading,
    this.customers = const [],
    this.query = '',
    this.error,
  });

  CustomersState copyWith({
    LoadStatus? status,
    List<CustomerView>? customers,
    String? query,
    String? error,
  }) =>
      CustomersState(
        status: status ?? this.status,
        customers: customers ?? this.customers,
        query: query ?? this.query,
        error: error,
      );

  @override
  List<Object?> get props => [
        status,
        customers
            .map((c) =>
                '${c.customer.id}${c.customer.updatedAt}${c.customer.syncStatus}${c.siteCount}${c.noteCount}')
            .toList(),
        query,
        error,
      ];
}

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  CustomersBloc({required this.repository, required this.userId})
      : super(const CustomersState()) {
    on<CustomersStarted>((e, emit) => _load(emit));
    on<CustomersChanged>((e, emit) => _load(emit, silent: true));
    on<CustomersQueryChanged>((e, emit) async {
      emit(state.copyWith(query: e.query));
      await _load(emit, silent: true);
    });
    _sub = DataEvents.stream.listen((_) => add(const CustomersChanged()));
    add(const CustomersStarted());
  }

  final CustomerRepository repository;
  final String userId;
  StreamSubscription<void>? _sub;

  Future<void> _load(Emitter<CustomersState> emit, {bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: LoadStatus.loading));
    try {
      final list = await repository.list(userId, query: state.query);
      emit(CustomersState(status: LoadStatus.loaded, customers: list, query: state.query));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
