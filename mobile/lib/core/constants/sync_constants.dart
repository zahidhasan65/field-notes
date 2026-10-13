class SyncStatus {
  SyncStatus._();

  static const String synced = 'SYNCED';
  static const String pendingCreate = 'PENDING_CREATE';
  static const String pendingUpdate = 'PENDING_UPDATE';
  static const String pendingDelete = 'PENDING_DELETE';
  static const String syncFailed = 'SYNC_FAILED';
}

class SyncOperation {
  SyncOperation._();

  static const String create = 'CREATE';
  static const String update = 'UPDATE';
  static const String delete = 'DELETE';
}

class SyncEntityType {
  SyncEntityType._();

  static const String customer = 'CUSTOMER';
  static const String site = 'SITE';
  static const String fieldNote = 'FIELD_NOTE';
}

class SyncQueueStatus {
  SyncQueueStatus._();

  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String failed = 'FAILED';
}

class SyncLimits {
  SyncLimits._();

  /// After this many failed attempts an item waits for a manual retry.
  static const int maxRetries = 5;
}
