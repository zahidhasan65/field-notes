import 'dart:convert';

import '../../core/constants/sync_constants.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/session_storage.dart';
import '../local/models/sync_queue_item.dart';
import 'sync_remote_data_source.dart';

class HttpSyncRemoteDataSource implements SyncRemoteDataSource {
  final ApiService apiService;
  final SessionStorage sessionStorage;

  HttpSyncRemoteDataSource({
    ApiService? apiService,
    SessionStorage? sessionStorage,
  })  : apiService = apiService ?? ApiService(),
        sessionStorage = sessionStorage ?? SessionStorage();

  @override
  Future<void> create(SyncQueueItem item) async {
    await _send(item, SyncOperation.create);
  }

  @override
  Future<void> update(SyncQueueItem item) async {
    await _send(item, SyncOperation.update);
  }

  @override
  Future<void> delete(SyncQueueItem item) async {
    await _send(item, SyncOperation.delete);
  }

  Future<void> _send(
    SyncQueueItem item,
    String operation,
  ) async {
    final token = await sessionStorage.getToken();

    if (token == null || token.isEmpty) {
      throw StateError('Authentication token is not available.');
    }

    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    final request = _buildRequest(
      item: item,
      operation: operation,
      payload: payload,
    );

    final response = switch (operation) {
      SyncOperation.create => await apiService.post(
          endpoint: request.endpoint,
          body: request.body,
          token: token,
        ),
      SyncOperation.update => await apiService.put(
          endpoint: request.endpoint,
          body: request.body,
          token: token,
        ),
      SyncOperation.delete => await apiService.delete(
          endpoint: request.endpoint,
          token: token,
        ),
      _ => throw UnsupportedError(
          'Unsupported sync operation: $operation',
        ),
    };

    if (!response.isSuccess) {
      throw Exception(
        'Sync failed (${response.statusCode}): '
        '${response.errorMessage ?? 'Unknown error'}',
      );
    }
  }

  _SyncRequest _buildRequest({
    required SyncQueueItem item,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    switch (item.entityType) {
      case SyncEntityType.customer:
        return _buildCustomerRequest(
          item,
          operation,
          payload,
        );

      case SyncEntityType.site:
        return _buildSiteRequest(
          item,
          operation,
          payload,
        );

      case SyncEntityType.fieldNote:
        return _buildFieldNoteRequest(
          item,
          operation,
          payload,
        );

      default:
        throw UnsupportedError(
          'Unsupported entity type: ${item.entityType}',
        );
    }
  }

  _SyncRequest _buildCustomerRequest(
    SyncQueueItem item,
    String operation,
    Map<String, dynamic> payload,
  ) {
    final body = {
      'name': payload['name'],
      'contactInformation': payload['contactInformation'],
    };

    return _SyncRequest(
      endpoint: operation == SyncOperation.create
          ? '/customers'
          : '/customers/${item.entityId}',
      body: operation == SyncOperation.delete ? null : body,
    );
  }

  _SyncRequest _buildSiteRequest(
    SyncQueueItem item,
    String operation,
    Map<String, dynamic> payload,
  ) {
    final customerId = payload['customerId'];

    if (customerId == null || customerId.toString().isEmpty) {
      throw StateError(
        'customerId is required to sync site ${item.entityId}.',
      );
    }

    final baseEndpoint = '/customers/$customerId/sites';

    final body = {
      'name': payload['siteName'],
      'address': payload['address'],
    };

    return _SyncRequest(
      endpoint: operation == SyncOperation.create
          ? baseEndpoint
          : '$baseEndpoint/${item.entityId}',
      body: operation == SyncOperation.delete ? null : body,
    );
  }

  _SyncRequest _buildFieldNoteRequest(
    SyncQueueItem item,
    String operation,
    Map<String, dynamic> payload,
  ) {
    final siteId = payload['siteId'];

    if (siteId == null || siteId.toString().isEmpty) {
      throw StateError(
        'siteId is required to sync field note ${item.entityId}.',
      );
    }

    final baseEndpoint = '/sites/$siteId/field-notes';

    final note = payload['note'] ??
        payload['description'] ??
        payload['title'];

    if (operation != SyncOperation.delete &&
        (note == null || note.toString().trim().isEmpty)) {
      throw StateError(
        'note is required to sync field note ${item.entityId}.',
      );
    }

    return _SyncRequest(
      endpoint: operation == SyncOperation.create
          ? baseEndpoint
          : '$baseEndpoint/${item.entityId}',
      body: operation == SyncOperation.delete
          ? null
          : {'note': note},
    );
  }
}

class _SyncRequest {
  final String endpoint;
  final Map<String, dynamic>? body;

  const _SyncRequest({
    required this.endpoint,
    required this.body,
  });
}
