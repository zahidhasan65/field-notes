class SyncStatus {
  static const String synced = 'SYNCED';
  static const String pendingCreate = 'PENDING_CREATE';
  static const String pendingUpdate = 'PENDING_UPDATE';
  static const String pendingDelete = 'PENDING_DELETE';
  static const String syncFailed = 'SYNC_FAILED';
}

class SyncQueueStatus {
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String failed = 'FAILED';
}

class SyncOperation {
  static const String create = 'CREATE';
  static const String update = 'UPDATE';
  static const String delete = 'DELETE';
}

class SyncEntityType {
  static const String customer = 'CUSTOMER';
  static const String site = 'SITE';
  static const String fieldNote = 'FIELD_NOTE';
}
