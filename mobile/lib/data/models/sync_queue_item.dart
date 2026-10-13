import '../../core/core.dart';

class SyncQueueItem {
  final int? id;
  final String userId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload; // JSON
  final String createdAt;
  final int retryCount;
  final String? lastAttemptAt;
  final String status;
  final String? errorMessage;

  const SyncQueueItem({
    this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.status = SyncQueueStatus.pending,
    this.errorMessage,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation,
        'payload': payload,
        'created_at': createdAt,
        'retry_count': retryCount,
        'last_attempt_at': lastAttemptAt,
        'status': status,
        'error_message': errorMessage,
      };

  factory SyncQueueItem.fromMap(Map<String, Object?> m) => SyncQueueItem(
        id: m['id'] as int?,
        userId: (m['user_id'] as String?) ?? '',
        entityType: m['entity_type'] as String,
        entityId: m['entity_id'] as String,
        operation: m['operation'] as String,
        payload: (m['payload'] as String?) ?? '{}',
        createdAt: m['created_at'] as String,
        retryCount: (m['retry_count'] as int?) ?? 0,
        lastAttemptAt: m['last_attempt_at'] as String?,
        status: (m['status'] as String?) ?? SyncQueueStatus.pending,
        errorMessage: m['error_message'] as String?,
      );
}
