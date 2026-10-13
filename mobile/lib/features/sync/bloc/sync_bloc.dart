import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/local/data_sources/sync_queue_local_data_source.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncStarted extends SyncEvent {
  final String userId;
  const SyncStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SyncStopped extends SyncEvent {
  const SyncStopped();
}

class SyncRequested extends SyncEvent {
  final Completer<void>? completer;
  const SyncRequested({this.completer});
}

class SyncRetryFailedRequested extends SyncEvent {
  const SyncRetryFailedRequested();
}

class SyncConnectivityChanged extends SyncEvent {
  final bool isOnline;
  const SyncConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

class SyncCountsRequested extends SyncEvent {
  const SyncCountsRequested();
}

class SyncBlocState extends Equatable {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final bool sessionExpired;

  const SyncBlocState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncedAt,
    this.sessionExpired = false,
  });

  int get unsyncedCount => pendingCount + failedCount;

  SyncUiStatus get uiStatus {
    if (!isOnline) return SyncUiStatus.offline;
    if (isSyncing) return SyncUiStatus.syncing;
    if (failedCount > 0) return SyncUiStatus.failed;
    if (pendingCount > 0) return SyncUiStatus.pending;
    return SyncUiStatus.online;
  }

  SyncBlocState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncedAt,
    bool? sessionExpired,
  }) => SyncBlocState(
    isOnline: isOnline ?? this.isOnline,
    isSyncing: isSyncing ?? this.isSyncing,
    pendingCount: pendingCount ?? this.pendingCount,
    failedCount: failedCount ?? this.failedCount,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    sessionExpired: sessionExpired ?? this.sessionExpired,
  );

  @override
  List<Object?> get props => [
    isOnline,
    isSyncing,
    pendingCount,
    failedCount,
    lastSyncedAt,
    sessionExpired,
  ];
}






class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  SyncBloc({
    required this.engine,
    required this.connectivity,
    required this.queue,
    required this.settings,
  }) : super(const SyncBlocState()) {
    on<SyncStarted>(_onStarted);
    on<SyncStopped>(_onStopped);
    on<SyncRequested>(_onRequested);
    on<SyncRetryFailedRequested>(_onRetryFailed);
    on<SyncConnectivityChanged>(_onConnectivityChanged);
    on<SyncCountsRequested>(_onCounts);
  }

  final SyncEngine engine;
  final ConnectivityService connectivity;
  final SyncQueueLocalDataSource queue;
  final AppSettingsRepository settings;

  String? _userId;
  bool _busy = false;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<void>? _dataSub;
  Timer? _timer;

  Future<void> _onStarted(
    SyncStarted event,
    Emitter<SyncBlocState> emit,
  ) async {
    _userId = event.userId;
    await queue.resetStuckProcessing(event.userId);

    final online = await connectivity.isOnline();
    final last = await settings.getLastSynced(event.userId);
    emit(
      SyncBlocState(
        isOnline: online,
        lastSyncedAt: last,
        pendingCount: await queue.pendingCount(event.userId),
        failedCount: await queue.failedCount(event.userId),
      ),
    );

    await _connectivitySub?.cancel();
    _connectivitySub = connectivity.onConnectivityChanged.listen(
      (online) => add(SyncConnectivityChanged(online)),
    );

    await _dataSub?.cancel();
    _dataSub = DataEvents.stream.listen(
      (_) => add(const SyncCountsRequested()),
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (state.isOnline && !state.isSyncing) add(const SyncRequested());
    });

    if (online) add(const SyncRequested());
  }

  Future<void> _onStopped(
    SyncStopped event,
    Emitter<SyncBlocState> emit,
  ) async {
    _userId = null;
    _timer?.cancel();
    await _connectivitySub?.cancel();
    await _dataSub?.cancel();
    emit(const SyncBlocState());
  }

  Future<void> _onConnectivityChanged(
    SyncConnectivityChanged event,
    Emitter<SyncBlocState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
    if (event.isOnline && _userId != null) add(const SyncRequested());
  }

  Future<void> _onCounts(
    SyncCountsRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) return;
    emit(
      state.copyWith(
        pendingCount: await queue.pendingCount(userId),
        failedCount: await queue.failedCount(userId),
      ),
    );
  }

  Future<void> _onRetryFailed(
    SyncRetryFailedRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) return;
    await queue.resetFailed(userId);
    DataEvents.notify();
    add(const SyncRequested());
  }

  Future<void> _onRequested(
    SyncRequested event,
    Emitter<SyncBlocState> emit,
  ) async {
    final userId = _userId;

    if (userId == null || _busy) {
      final completer = event.completer;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
      return;
    }

    _busy = true;

    try {
      final online = await connectivity.isOnline();

      if (!online) {
        emit(state.copyWith(isOnline: false));
        return;
      }

      emit(state.copyWith(isOnline: true, isSyncing: true));

      final result = await engine.sync(userId);
      final healthy =
          !result.offline && !result.authExpired && result.failed == 0;

      emit(
        state.copyWith(
          isOnline: !result.offline,
          sessionExpired: result.authExpired,
          lastSyncedAt: healthy ? DateTime.now() : state.lastSyncedAt,
        ),
      );
    } catch (e, st) {
      debugPrint('SYNC ERROR: $e\n$st');
    } finally {
      _busy = false;

      try {
        if (_userId == userId) {
          final pending = await queue.pendingCount(userId);
          final failed = await queue.failedCount(userId);

          emit(
            state.copyWith(
              isSyncing: false,
              pendingCount: pending,
              failedCount: failed,
            ),
          );
        } else {
          emit(state.copyWith(isSyncing: false));
        }
      } catch (e, st) {
        debugPrint('SYNC STATE REFRESH ERROR: $e\n$st');
        emit(state.copyWith(isSyncing: false));
      } finally {
        final completer = event.completer;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    _dataSub?.cancel();
    return super.close();
  }
}
