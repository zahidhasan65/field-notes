import '../local/data_sources/field_note_local_data_source.dart';
import '../local/models/field_note_local.dart';
import '../local/models/sync_queue_item.dart';

class LocalFieldNoteRepository {
  final FieldNoteLocalDataSource localDataSource;

  LocalFieldNoteRepository({
    FieldNoteLocalDataSource? localDataSource,
  }) : localDataSource = localDataSource ?? FieldNoteLocalDataSource();

  Future<void> saveFieldNote(FieldNoteLocal fieldNote) async =>
      localDataSource.insertFieldNote(fieldNote);

  Future<void> createFieldNoteWithSyncQueue({
    required FieldNoteLocal fieldNote,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.createFieldNoteWithSyncQueue(
        fieldNote: fieldNote,
        queueItem: queueItem,
      );

  Future<void> updateFieldNoteWithSyncQueue({
    required FieldNoteLocal fieldNote,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.updateFieldNoteWithSyncQueue(
        fieldNote: fieldNote,
        queueItem: queueItem,
      );

  Future<void> deleteFieldNoteWithSyncQueue({
    required String id,
    required String deletedAt,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.softDeleteFieldNoteWithSyncQueue(
        id: id,
        deletedAt: deletedAt,
        queueItem: queueItem,
      );

  Future<FieldNoteLocal?> getFieldNoteById(String id) async =>
      localDataSource.getFieldNoteById(id);

  Future<List<FieldNoteLocal>> getFieldNotes(String siteId) async =>
      localDataSource.getFieldNotes(siteId);

  Future<void> updateFieldNote(FieldNoteLocal fieldNote) async =>
      localDataSource.updateFieldNote(fieldNote);

  Future<void> deleteFieldNote(String id, String deletedAt) async =>
      localDataSource.softDeleteFieldNote(id, deletedAt);

  Future<void> markAsSynced(String id) async =>
      localDataSource.markAsSynced(id);

  Future<void> markAsSyncFailed(String id) async =>
      localDataSource.markAsSyncFailed(id);
}

