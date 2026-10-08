import 'package:flutter/foundation.dart';

import '../../core/storage/session_storage.dart';
import '../local/data_sources/customer_local_data_source.dart';
import '../local/data_sources/field_note_local_data_source.dart';
import '../local/data_sources/site_local_data_source.dart';
import '../local/models/customer_local.dart';
import '../local/models/field_note_local.dart';
import '../local/models/site_local.dart';
import '../remote/restore_remote_data_source.dart';

class RestoreRepository {
  final RestoreRemoteDataSource remoteDataSource;
  final CustomerLocalDataSource customerLocalDataSource;
  final SiteLocalDataSource siteLocalDataSource;
  final FieldNoteLocalDataSource fieldNoteLocalDataSource;
  final SessionStorage sessionStorage;

  RestoreRepository({
    RestoreRemoteDataSource? remoteDataSource,
    CustomerLocalDataSource? customerLocalDataSource,
    SiteLocalDataSource? siteLocalDataSource,
    FieldNoteLocalDataSource? fieldNoteLocalDataSource,
    SessionStorage? sessionStorage,
  })  : remoteDataSource =
            remoteDataSource ?? RestoreRemoteDataSource(),
        customerLocalDataSource =
            customerLocalDataSource ?? CustomerLocalDataSource(),
        siteLocalDataSource =
            siteLocalDataSource ?? SiteLocalDataSource(),
        fieldNoteLocalDataSource =
            fieldNoteLocalDataSource ?? FieldNoteLocalDataSource(),
        sessionStorage = sessionStorage ?? SessionStorage();

  Future<void> restore() async {
    final userId = await sessionStorage.getUserId();

    if (userId == null || userId.isEmpty) {
      throw StateError('User ID is not available.');
    }

    final remoteCustomers =
        await remoteDataSource.getCustomers();

    final customers = remoteCustomers.map((data) {
      return CustomerLocal(
        id: data['id'] as String,
        userId: userId,
        name: data['name'] as String,
        contactInformation:
            data['contactInformation'] as String?,
        createdAt: data['createdAt'] as String,
        updatedAt: data['updatedAt'] as String,
        deletedAt: null,
        syncStatus: 'SYNCED',
      );
    }).toList();

    await customerLocalDataSource.restoreCustomers(customers);

    for (final customer in customers) {
      final remoteSites =
          await remoteDataSource.getSites(customer.id);

      final sites = remoteSites.map((data) {
        return SiteLocal(
          id: data['id'] as String,
          customerId: customer.id,
          siteName: data['name'] as String,
          address: data['address'] as String,
          createdAt: data['createdAt'] as String,
          updatedAt: data['updatedAt'] as String,
          deletedAt: null,
          syncStatus: 'SYNCED',
        );
      }).toList();

      await siteLocalDataSource.restoreSites(sites);

      for (final site in sites) {
        final remoteFieldNotes =
            await remoteDataSource.getFieldNotes(site.id);

        final fieldNotes = remoteFieldNotes.map((data) {
          return FieldNoteLocal(
            id: data['id'] as String,
            siteId: site.id,
            title: null,
            description: data['note'] as String?,
            latitude: null,
            longitude: null,
            noteDatetime: null,
            status: null,
            photoUrl: null,
            createdAt: data['createdAt'] as String,
            updatedAt: data['updatedAt'] as String,
            deletedAt: null,
            syncStatus: 'SYNCED',
          );
        }).toList();

        await fieldNoteLocalDataSource
            .restoreFieldNotes(fieldNotes);
      }
    }

    debugPrint('Data restore completed successfully.');
  }
}
