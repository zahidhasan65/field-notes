enum AppNotificationType { info, success, warning, error, sync, offline }

enum NotificationCategory { sync, connection, account }

class AppNotification {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body = '',
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'created_at': createdAt.toUtc().toIso8601String(),
        'is_read': isRead ? 1 : 0,
      };

  factory AppNotification.fromMap(Map<String, Object?> m) => AppNotification(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        type: AppNotificationType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => AppNotificationType.info,
        ),
        title: m['title'] as String,
        body: (m['body'] as String?) ?? '',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
        isRead: (m['is_read'] as int?) == 1,
      );
}
