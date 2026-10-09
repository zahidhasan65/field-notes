import 'dart:async';

import '../../core/connectivity/connectivity_service.dart';
import 'sync_engine.dart';

class SyncCoordinator {
  final ConnectivityService connectivityService;
  final SyncEngine syncEngine;

  StreamSubscription<bool>? _connectivitySubscription;

  bool _isSyncing = false;
  bool _started = false;

  SyncCoordinator({
    required this.connectivityService,
    required this.syncEngine,
  });

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;

    final isOnline = await connectivityService.isOnline();

    if (isOnline) {
      await syncNow();
    }

    _connectivitySubscription = connectivityService.onConnectivityChanged
        .listen((isOnline) {
          if (isOnline) {
            syncNow();
          }
        });
  }

  Future<void> syncNow() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      await syncEngine.sync();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _started = false;
  }
}
