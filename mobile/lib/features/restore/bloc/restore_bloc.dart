import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';

sealed class RestoreEvent extends Equatable {
  const RestoreEvent();
  @override
  List<Object?> get props => [];
}

class RestoreStarted extends RestoreEvent {
  final String userId;
  const RestoreStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class RestoreRetried extends RestoreEvent {
  const RestoreRetried();
}

enum RestoreStatus { running, success, failure }

class RestoreState extends Equatable {
  final RestoreStatus status;

  /// Stages already finished -> number of records found.
  final Map<RestoreStage, int> done;
  final String? error;

  const RestoreState({
    this.status = RestoreStatus.running,
    this.done = const {},
    this.error,
  });

  RestoreState copyWith({
    RestoreStatus? status,
    Map<RestoreStage, int>? done,
    String? error,
    bool clearError = false,
  }) =>
      RestoreState(
        status: status ?? this.status,
        done: done ?? this.done,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, done, error];
}

class RestoreBloc extends Bloc<RestoreEvent, RestoreState> {
  RestoreBloc({required this.engine}) : super(const RestoreState()) {
    on<RestoreStarted>((e, emit) async {
      _userId = e.userId;
      await _run(emit);
    });
    on<RestoreRetried>((e, emit) async => _run(emit));
  }

  final SyncEngine engine;
  String? _userId;

  Future<void> _run(Emitter<RestoreState> emit) async {
    final userId = _userId;
    if (userId == null) return;

    emit(const RestoreState());
    try {
      await engine.restore(userId, onStage: (stage, count) async {
        emit(state.copyWith(done: {...state.done, stage: count}));
        // short pause so the user can see each step
        await Future.delayed(const Duration(milliseconds: 350));
      });
      emit(state.copyWith(status: RestoreStatus.success));
    } on NetworkException catch (e) {
      emit(state.copyWith(status: RestoreStatus.failure, error: e.message));
    } on AuthExpiredException catch (e) {
      emit(state.copyWith(status: RestoreStatus.failure, error: e.message));
    } on ApiException catch (e) {
      emit(state.copyWith(status: RestoreStatus.failure, error: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: RestoreStatus.failure,
        error: 'Could not restore your data. Please try again.',
      ));
    }
  }
}
