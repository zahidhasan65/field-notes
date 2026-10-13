import 'dart:convert';

import '../../core/core.dart';
import '../../services/photo_storage.dart';
import '../local/data_sources/customer_local_data_source.dart';
import '../local/data_sources/field_note_local_data_source.dart';
import '../local/data_sources/site_local_data_source.dart';
import '../local/data_sources/sync_queue_local_data_source.dart';
import '../local/database/database_helper.dart';
import '../models/customer_local.dart';
import '../models/sync_queue_item.dart';
import '../models/views.dart';
import 'data_events.dart';


class CustomerRepository {
  CustomerRepository({
    required this.helper,
    required this.customers,
    required this.sites,
    required this.notes,
    required this.queue,
    required this.photos,
  });

  final DatabaseHelper helper;
  final CustomerLocalDataSource customers;
  final SiteLocalDataSource sites;
  final FieldNoteLocalDataSource notes;
  final SyncQueueLocalDataSource queue;
  final PhotoStorage photos;

  Future<List<CustomerView>> list(String userId, {String query = ''}) =>
      customers.listViews(userId, query: query);

  Future<CustomerView?> getView(String id) => customers.getView(id);

  Future<int> count(String userId) => customers.count(userId);

  Future<DeleteImpact> deleteImpact(String customerId) async {
    final v = await customers.getView(customerId);
    return DeleteImpact(sites: v?.siteCount ?? 0, notes: v?.noteCount ?? 0);
  }

  Future<CustomerLocal> create(String userId, CustomerDraft d) async {
    final now = nowIso();
    final c = CustomerLocal(
      id: newUuid(),
      userId: userId,
      name: d.name.trim(),
      contactPerson: blankToNull(d.contactPerson),
      email: blankToNull(d.email),
      phone: blankToNull(d.phone),
      address: blankToNull(d.address),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    final db = await helper.database;
    await db.transaction((txn) async {
      await customers.upsert(txn, c);
      await queue.enqueueUpsert(
        txn,
        SyncQueueItem(
          userId: userId,
          entityType: SyncEntityType.customer,
          entityId: c.id,
          operation: SyncOperation.create,
          payload: jsonEncode(c.toApiPayload()),
          createdAt: now,
        ),
      );
    });

    DataEvents.notify();
    return c;
  }

  Future<void> update(CustomerLocal existing, CustomerDraft d) async {
    final now = nowIso();
    final db = await helper.database;

    await db.transaction((txn) async {
      final draft = CustomerLocal(
        id: existing.id,
        userId: existing.userId,
        name: d.name.trim(),
        contactPerson: blankToNull(d.contactPerson),
        email: blankToNull(d.email),
        phone: blankToNull(d.phone),
        address: blankToNull(d.address),
        createdAt: existing.createdAt,
        updatedAt: now,
      );

      final op = await queue.enqueueUpsert(
        txn,
        SyncQueueItem(
          userId: existing.userId,
          entityType: SyncEntityType.customer,
          entityId: existing.id,
          operation: SyncOperation.update,
          payload: jsonEncode(draft.toApiPayload()),
          createdAt: now,
        ),
      );

      await customers.upsert(
        txn,
        draft.copyWith(
          syncStatus: op == SyncOperation.create
              ? SyncStatus.pendingCreate
              : SyncStatus.pendingUpdate,
        ),
      );
    });

    DataEvents.notify();
  }

  Future<void> delete(CustomerLocal c) async {
    final now = nowIso();
    final db = await helper.database;
    var photoPaths = <String>[];

    await db.transaction((txn) async {
      final siteIds = await sites.idsByCustomer(txn, c.id);
      final noteIds = await notes.idsBySites(txn, siteIds);
      photoPaths = await notes.photoPathsByIds(txn, noteIds);

      await queue.removeForEntities(txn, SyncEntityType.fieldNote, noteIds);
      await queue.removeForEntities(txn, SyncEntityType.site, siteIds);
      await notes.softDeleteMany(txn, noteIds, now, syncStatus: SyncStatus.synced);
      await sites.softDeleteMany(txn, siteIds, now, syncStatus: SyncStatus.synced);

      final neverSynced =
          await queue.hasPendingCreate(txn, SyncEntityType.customer, c.id);
      if (neverSynced) {
        await queue.removeForEntities(txn, SyncEntityType.customer, [c.id]);
        await customers.softDeleteMany(txn, [c.id], now,
            syncStatus: SyncStatus.synced);
      } else {
        await queue.enqueueDelete(
          txn,
          SyncQueueItem(
            userId: c.userId,
            entityType: SyncEntityType.customer,
            entityId: c.id,
            operation: SyncOperation.delete,
            payload: jsonEncode({'id': c.id}),
            createdAt: now,
          ),
        );
        await customers.softDeleteMany(txn, [c.id], now,
            syncStatus: SyncStatus.pendingDelete);
      }
    });

    await photos.deleteAll(photoPaths);
    DataEvents.notify();
  }
}
