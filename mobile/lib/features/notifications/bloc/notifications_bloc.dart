import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/data.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsStarted extends NotificationsEvent {
  final String userId;
  const NotificationsStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class NotificationsStopped extends NotificationsEvent {
  const NotificationsStopped();
}

class NotificationsChanged extends NotificationsEvent {
  const NotificationsChanged();
}

class NotificationsMarkAllRead extends NotificationsEvent {
  const NotificationsMarkAllRead();
}

class NotificationRead extends NotificationsEvent {
  final String id;
  const NotificationRead(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationDeleted extends NotificationsEvent {
  final String id;
  const NotificationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationsCleared extends NotificationsEvent {
  const NotificationsCleared();
}

class NotificationsState extends Equatable {
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationsState({this.items = const [], this.unreadCount = 0});

  @override
  List<Object?> get props =>
      [items.map((n) => '${n.id}${n.isRead}').toList(), unreadCount];
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required this.repository}) : super(const NotificationsState()) {
    on<NotificationsStarted>((e, emit) async {
      _userId = e.userId;
      await _sub?.cancel();
      _sub = NotificationRepository.changes.listen((_) => add(const NotificationsChanged()));
      await _load(emit);
    });
    on<NotificationsStopped>((e, emit) async {
      _userId = null;
      await _sub?.cancel();
      emit(const NotificationsState());
    });
    on<NotificationsChanged>((e, emit) => _load(emit));
    on<NotificationsMarkAllRead>((e, emit) async {
      final id = _userId;
      if (id != null) await repository.markAllRead(id);
    });
    on<NotificationRead>((e, emit) => repository.markRead(e.id));
    on<NotificationDeleted>((e, emit) => repository.delete(e.id));
    on<NotificationsCleared>((e, emit) async {
      final id = _userId;
      if (id != null) await repository.clear(id);
    });
  }

  final NotificationRepository repository;
  String? _userId;
  StreamSubscription<void>? _sub;

  Future<void> _load(Emitter<NotificationsState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    // read first, then emit a NEW state (never build it from a stale `state`)
    final items = await repository.list(userId);
    final unread = await repository.unreadCount(userId);
    emit(NotificationsState(items: items, unreadCount: unread));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
