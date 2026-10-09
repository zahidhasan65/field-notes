class SyncQueueItem {
  final int? id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final String createdAt;
  final int retryCount;
  final String? lastAttemptAt;
  final String status;
  final String? errorMessage;

  SyncQueueItem({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    required this.status,
    this.errorMessage,
  });

  SyncQueueItem copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    String? createdAt,
    int? retryCount,
    String? lastAttemptAt,
    String? status,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: map['operation'] as String,
      payload: map['payload'] as String,
      createdAt: map['created_at'] as String,
      retryCount: (map['retry_count'] as int?) ?? 0,
      lastAttemptAt: map['last_attempt_at'] as String?,
      status: map['status'] as String,
      errorMessage: map['error_message'] as String?,
    );
  }
}
