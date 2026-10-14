import 'dart:async';

import '../../core/core.dart';
import '../local/data_sources/notification_local_data_source.dart';
import '../models/app_notification.dart';
import 'app_settings_repository.dart';


class NotificationRepository {
  NotificationRepository({required this.local, required this.settings});

  final NotificationLocalDataSource local;
  final AppSettingsRepository settings;

  static final StreamController<void> _changes = StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> add(
    String userId, {
    required AppNotificationType type,
    required String title,
    String body = '',
    NotificationCategory category = NotificationCategory.account,
  }) async {
    // respect the switches in Settings
    if (category == NotificationCategory.sync && !await settings.getNotifySync()) return;
    if (category == NotificationCategory.connection && !await settings.getNotifyOffline()) return;

    await local.insert(AppNotification(
      id: newUuid(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    ));
    await local.trim(userId);
    _emit();
  }

  Future<List<AppNotification>> list(String userId) => local.list(userId);

  Future<int> unreadCount(String userId) => local.unreadCount(userId);

  Future<void> markAllRead(String userId) async {
    await local.markAllRead(userId);
    _emit();
  }

  Future<void> markRead(String id) async {
    await local.markRead(id);
    _emit();
  }

  Future<void> delete(String id) async {
    await local.delete(id);
    _emit();
  }

  Future<void> clear(String userId) async {
    await local.clear(userId);
    _emit();
  }
}
