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


abstract class SyncRemoteDataSource {
  Future<void> push(SyncQueueItem item);

  Future<String?> uploadPhoto(String noteId, String filePath);

  Future<void> deletePhoto(String noteId);

  Future<RemoteChanges> fetchChanges({DateTime? since});

  Future<List<int>?> downloadPhoto(String noteId);
}
