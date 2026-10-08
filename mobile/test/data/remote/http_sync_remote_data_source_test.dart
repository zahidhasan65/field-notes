import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/core/storage/session_storage.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';
import 'package:mobile/data/remote/http_sync_remote_data_source.dart';
import 'package:mobile/core/network/api_service.dart';

class FakeApiService extends ApiService {
  String? lastMethod;
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;
  String? lastToken;

  @override
  Future<ApiResponse> post({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    lastMethod = 'POST';
    lastEndpoint = endpoint;
    lastBody = body;
    lastToken = token;

    return ApiResponse(
      isSuccess: true,
      statusCode: 201,
      data: {},
    );
  }

  @override
  Future<ApiResponse> put({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    lastMethod = 'PUT';
    lastEndpoint = endpoint;
    lastBody = body;
    lastToken = token;

    return ApiResponse(
      isSuccess: true,
      statusCode: 200,
      data: {},
    );
  }

  @override
  Future<ApiResponse> delete({
    required String endpoint,
    String? token,
  }) async {
    lastMethod = 'DELETE';
    lastEndpoint = endpoint;
    lastBody = null;
    lastToken = token;

    return ApiResponse(
      isSuccess: true,
      statusCode: 204,
      data: null,
    );
  }
}

class FakeSessionStorage extends SessionStorage {
  @override
  Future<String?> getToken() async {
    return 'test-token';
  }
}

SyncQueueItem createQueueItem({
  required String entityType,
  required String entityId,
  required String operation,
  required Map<String, dynamic> payload,
}) {
  return SyncQueueItem(
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payload: jsonEncode(payload),
    createdAt: DateTime.now().toIso8601String(),
    status: 'PENDING',
  );
}

void main() {
  late FakeApiService apiService;
  late HttpSyncRemoteDataSource remoteDataSource;

  setUp(() {
    apiService = FakeApiService();

    remoteDataSource = HttpSyncRemoteDataSource(
      apiService: apiService,
      sessionStorage: FakeSessionStorage(),
    );
  });

  test('creates customer with correct endpoint and payload', () async {
    final item = createQueueItem(
      entityType: 'CUSTOMER',
      entityId: 'customer-1',
      operation: 'CREATE',
      payload: {
        'name': 'ABC Customer',
        'contactInformation': '01700000000',
      },
    );

    await remoteDataSource.create(item);

    expect(apiService.lastMethod, 'POST');
    expect(apiService.lastEndpoint, '/customers');
    expect(
      apiService.lastBody,
      {
        'name': 'ABC Customer',
        'contactInformation': '01700000000',
      },
    );
    expect(apiService.lastToken, 'test-token');
  });

  test('updates site with customer dependency', () async {
    final item = createQueueItem(
      entityType: 'SITE',
      entityId: 'site-1',
      operation: 'UPDATE',
      payload: {
        'customerId': 'customer-1',
        'siteName': 'Updated Site',
        'address': 'Dhaka',
      },
    );

    await remoteDataSource.update(item);

    expect(apiService.lastMethod, 'PUT');
    expect(
      apiService.lastEndpoint,
      '/customers/customer-1/sites/site-1',
    );
    expect(
      apiService.lastBody,
      {
        'name': 'Updated Site',
        'address': 'Dhaka',
      },
    );
  });

  test('creates field note with site dependency', () async {
    final item = createQueueItem(
      entityType: 'FIELD_NOTE',
      entityId: 'note-1',
      operation: 'CREATE',
      payload: {
        'siteId': 'site-1',
        'title': 'Inspection',
        'description': 'Everything is okay.',
      },
    );

    await remoteDataSource.create(item);

    expect(apiService.lastMethod, 'POST');
    expect(
      apiService.lastEndpoint,
      '/sites/site-1/field-notes',
    );
    expect(
      apiService.lastBody,
      {
        'note': 'Everything is okay.',
      },
    );
  });

  test('deletes customer with correct endpoint', () async {
    final item = createQueueItem(
      entityType: 'CUSTOMER',
      entityId: 'customer-1',
      operation: 'DELETE',
      payload: {
        'name': 'ABC Customer',
      },
    );

    await remoteDataSource.delete(item);

    expect(apiService.lastMethod, 'DELETE');
    expect(apiService.lastEndpoint, '/customers/customer-1');
    expect(apiService.lastBody, isNull);
    expect(apiService.lastToken, 'test-token');
  });
}
