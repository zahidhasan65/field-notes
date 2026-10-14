import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../data/local/data_sources/sync_queue_local_data_source.dart';

// ---------------- events ----------------
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

// ---------------- state ----------------
class SyncBlocState extends Equatable {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final bool sessionExpired;

  final String? lastError;

  const SyncBlocState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncedAt,
    this.sessionExpired = false,
    this.lastError,
  });

  int get unsyncedCount => pendingCount + failedCount;

  SyncUiStatus get uiStatus {
    if (!isOnline) return SyncUiStatus.offline;
    if (isSyncing) return SyncUiStatus.syncing;
    if (failedCount > 0 || lastError != null) return SyncUiStatus.failed;
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
    String? lastError,
    bool clearError = false,
  }) =>
      SyncBlocState(
        isOnline: isOnline ?? this.isOnline,
        isSyncing: isSyncing ?? this.isSyncing,
        pendingCount: pendingCount ?? this.pendingCount,
        failedCount: failedCount ?? this.failedCount,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        sessionExpired: sessionExpired ?? this.sessionExpired,
        lastError: clearError ? null : (lastError ?? this.lastError),
      );

  @override
  List<Object?> get props => [
        isOnline,
        isSyncing,
        pendingCount,
        failedCount,
        lastSyncedAt,
        sessionExpired,
        lastError,
      ];
}

// ---------------- bloc ----------------






class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  SyncBloc({
    required this.engine,
    required this.connectivity,
    required this.queue,
    required this.settings,
    required this.notifications,
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
  final NotificationRepository notifications;

  static const _maxSyncDuration = Duration(minutes: 2);

  String? _userId;
  bool _busy = false;
  String? _lastNotifiedError;
  DateTime? _lastSyncEnd;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<void>? _dataSub;
  Timer? _timer;
  Timer? _autoTimer;

  Future<void> _onStarted(SyncStarted event, Emitter<SyncBlocState> emit) async {
    _userId = event.userId;
    await queue.resetStuckProcessing(event.userId);

    final online = await connectivity.isOnline();
    final last = await settings.getLastSynced(event.userId);
    emit(SyncBlocState(
      isOnline: online,
      lastSyncedAt: last,
      pendingCount: await queue.pendingCount(event.userId),
      failedCount: await queue.failedCount(event.userId),
    ));

    await _connectivitySub?.cancel();
    _connectivitySub = connectivity.onConnectivityChanged
        .listen((online) => add(SyncConnectivityChanged(online)));

    await _dataSub?.cancel();
    _dataSub = DataEvents.stream.listen((_) => add(const SyncCountsRequested()));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_userId != null && !_busy) add(const SyncRequested());
    });

    if (online) add(const SyncRequested());
  }

  Future<void> _onStopped(SyncStopped event, Emitter<SyncBlocState> emit) async {
    _userId = null;
    _timer?.cancel();
    _autoTimer?.cancel();
    await _connectivitySub?.cancel();
    await _dataSub?.cancel();
    emit(const SyncBlocState());
  }

  Future<void> _onConnectivityChanged(
      SyncConnectivityChanged event, Emitter<SyncBlocState> emit) async {
    final wasOnline = state.isOnline;
    emit(state.copyWith(isOnline: event.isOnline));

    if (event.isOnline != wasOnline) await _notifyConnection(event.isOnline);
    if (event.isOnline && _userId != null) add(const SyncRequested());
  }


  Future<void> _onCounts(SyncCountsRequested event, Emitter<SyncBlocState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    // IMPORTANT: await first, then read `state`. Writing
    // `emit(state.copyWith(x: await ...))` copies a STALE state (it is read before
    // the await) and could switch "isSyncing" back on after the sync had finished.
    final pending = await queue.pendingCount(userId);
    final failed = await queue.failedCount(userId);
    emit(state.copyWith(pendingCount: pending, failedCount: failed));
    _scheduleAutoSync();
  }

  void _scheduleAutoSync() {
    if (state.isSyncing || _busy || state.pendingCount == 0) return;

    // right after a sync ended the 45 s timer takes over (prevents tight retry loops)
    final last = _lastSyncEnd;
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 5)) {
      return;
    }

    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_userId != null && !state.isSyncing && !_busy) {
        add(const SyncRequested());
      }
    });
  }

  Future<void> _onRetryFailed(
      SyncRetryFailedRequested event, Emitter<SyncBlocState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    await queue.resetFailed(userId);
    DataEvents.notify();
    add(const SyncRequested());
  }

  Future<void> _onRequested(SyncRequested event, Emitter<SyncBlocState> emit) async {
    final userId = _userId;
    if (userId == null || _busy) {
      event.completer?.complete();
      return;
    }
    _busy = true;

    try {
      final online = await connectivity.isOnline();
      if (!online) {
        emit(state.copyWith(isOnline: false));
        return;
      }

      final wasOnline = state.isOnline;
      emit(state.copyWith(isOnline: true, isSyncing: true));

      final result = await engine.sync(userId).timeout(_maxSyncDuration);

      final healthy = !result.offline &&
          !result.authExpired &&
          result.failed == 0 &&
          result.error == null;

      // await first, then emit (see _onCounts)
      final pending = await queue.pendingCount(userId);
      final failed = await queue.failedCount(userId);

      emit(state.copyWith(
        isSyncing: false,
        isOnline: !result.offline,
        sessionExpired: result.authExpired,
        lastSyncedAt: healthy ? DateTime.now() : state.lastSyncedAt,
        pendingCount: pending,
        failedCount: failed,
        lastError: result.error,
        clearError: healthy,
      ));

      await _notifyResult(result, healthy: healthy, wasOnline: wasOnline);
    } on TimeoutException {
      emit(state.copyWith(
        isSyncing: false,
        lastError: 'The server did not answer in time. Check that the backend is running.',
      ));
    } catch (e) {
      emit(state.copyWith(isSyncing: false, lastError: 'Sync error: $e'));
    } finally {
      // safety net: never leave the spinner on
      if (state.isSyncing) emit(state.copyWith(isSyncing: false));
      _busy = false;
      _lastSyncEnd = DateTime.now();
      event.completer?.complete();
    }
  }

  // ---------------- notifications (bell icon) ----------------
  Future<void> _notifyResult(
    SyncResult result, {
    required bool healthy,
    required bool wasOnline,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      if (result.offline) {
        if (wasOnline) await _notifyConnection(false);
        return;
      }
      if (!wasOnline) await _notifyConnection(true);

      if (healthy) {
        _lastNotifiedError = null;
        if (result.pushed > 0) {
          await notifications.add(
            userId,
            type: AppNotificationType.success,
            category: NotificationCategory.sync,
            title: 'Synced',
            body: '${result.pushed} change${result.pushed == 1 ? '' : 's'} saved to the server.',
          );
        }
      } else if (!result.authExpired && result.error != null && result.error != _lastNotifiedError) {
        _lastNotifiedError = result.error;
        await notifications.add(
          userId,
          type: AppNotificationType.error,
          category: NotificationCategory.sync,
          title: 'Sync failed',
          body: result.error!,
        );
      }
    } catch (_) {
      // a notification problem must never break the sync
    }
  }

  Future<void> _notifyConnection(bool online) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await notifications.add(
        userId,
        type: online ? AppNotificationType.info : AppNotificationType.offline,
        category: NotificationCategory.connection,
        title: online ? 'Back online' : "You're offline",
        body: online
            ? 'Connection restored. Your changes are being synced.'
            : 'Your changes are saved on this device and will sync automatically when you are back online.',
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _autoTimer?.cancel();
    _connectivitySub?.cancel();
    _dataSub?.cancel();
    return super.close();
  }
}
