import '../models/sync_queue_item.dart';

class RemoteChanges {
  final DateTime serverTime;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> sites;
  final List<Map<String, dynamic>> notes;

  const RemoteChanges({
    required this.serverTime,
    required this.customers,
    required this.sites,
    required this.notes,
  });
}

/// Talks to the Spring Boot API. Throws NetworkException, AuthExpiredException
/// or ApiException.
abstract class SyncRemoteDataSource {
  Future<void> push(SyncQueueItem item);

  /// Uploads the photo file. Returns the remote photo path.
  Future<String?> uploadPhoto(String noteId, String filePath);

  Future<void> deletePhoto(String noteId);

  /// since == null -> full snapshot (restore), otherwise changes + tombstones.
  Future<RemoteChanges> fetchChanges({DateTime? since});

  Future<List<int>?> downloadPhoto(String noteId);
}
