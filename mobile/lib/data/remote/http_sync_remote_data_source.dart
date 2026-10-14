import 'dart:convert';

import '../../core/core.dart';
import '../models/sync_queue_item.dart';
import 'sync_remote_data_source.dart';

class HttpSyncRemoteDataSource implements SyncRemoteDataSource {
  HttpSyncRemoteDataSource({
    required this.apiService,
    required this.sessionStorage,
  });

  final ApiService apiService;
  final SessionStorage sessionStorage;

  Future<String> _token() async {
    final token = await sessionStorage.getToken();
    if (token == null || token.isEmpty) throw const AuthExpiredException();
    return token;
  }

  void _check(ApiResponse r, {bool okOn404 = false}) {
    if (r.isSuccess) return;
    if (r.isNetworkError) throw const NetworkException();
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw const AuthExpiredException();
    }
    if (okOn404 && r.statusCode == 404) return;
    throw ApiException(r.statusCode, r.errorMessage ?? 'Request failed');
  }

  Map<String, dynamic> _body(Map<String, dynamic> payload) =>
      {...payload}..remove('photoPath')..remove('removePhoto');

  @override
  Future<void> push(SyncQueueItem item) async {
    final token = await _token();
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    final id = item.entityId;
    final op = item.operation;

    late ApiResponse r;

    switch (item.entityType) {
      case SyncEntityType.customer:
        if (op == SyncOperation.create) {
          r = await apiService.post(
              endpoint: ApiConstants.customers(), body: _body(payload), token: token);
        } else if (op == SyncOperation.update) {
          r = await apiService.put(
              endpoint: ApiConstants.customer(id), body: _body(payload), token: token);
        } else {
          r = await apiService.delete(endpoint: ApiConstants.customer(id), token: token);
        }
      case SyncEntityType.site:
        final customerId = payload['customerId'] as String;
        if (op == SyncOperation.create) {
          r = await apiService.post(
              endpoint: ApiConstants.sites(customerId), body: _body(payload), token: token);
        } else if (op == SyncOperation.update) {
          r = await apiService.put(
              endpoint: ApiConstants.site(customerId, id),
              body: _body(payload),
              token: token);
        } else {
          r = await apiService.delete(
              endpoint: ApiConstants.site(customerId, id), token: token);
        }
      case SyncEntityType.fieldNote:
        final siteId = payload['siteId'] as String;
        if (op == SyncOperation.create) {
          r = await apiService.post(
              endpoint: ApiConstants.notes(siteId), body: _body(payload), token: token);
        } else if (op == SyncOperation.update) {
          r = await apiService.put(
              endpoint: ApiConstants.note(siteId, id), body: _body(payload), token: token);
        } else {
          r = await apiService.delete(
              endpoint: ApiConstants.note(siteId, id), token: token);
        }
      default:
        throw ApiException(0, 'Unknown entity type ${item.entityType}');
    }

    // Deleting something the server no longer has is fine.
    _check(r, okOn404: op == SyncOperation.delete);
  }

  @override
  Future<String?> uploadPhoto(String noteId, String filePath) async {
    final token = await _token();
    final r = await apiService.postFile(
      endpoint: ApiConstants.notePhoto(noteId),
      filePath: filePath,
      token: token,
    );
    _check(r);
    final data = r.data;
    return data is Map<String, dynamic> ? data['photoUrl'] as String? : null;
  }

  @override
  Future<void> deletePhoto(String noteId) async {
    final token = await _token();
    final r = await apiService.delete(
        endpoint: ApiConstants.notePhoto(noteId), token: token);
    _check(r, okOn404: true);
  }

  @override
  Future<RemoteChanges> fetchChanges({DateTime? since}) async {
    final token = await _token();
    final query = since == null
        ? ''
        : '?since=${Uri.encodeQueryComponent(since.toUtc().toIso8601String())}';
    final r = await apiService.get(
        endpoint: '${ApiConstants.syncChanges}$query', token: token);
    _check(r);

    final data = r.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(500, 'Unexpected response from the server.');
    }

    List<Map<String, dynamic>> list(String key) => ((data[key] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return RemoteChanges(
      serverTime:
          DateTime.tryParse((data['serverTime'] ?? '').toString()) ?? DateTime.now().toUtc(),
      customers: list('customers'),
      sites: list('sites'),
      notes: list('fieldNotes'),
    );
  }

  @override
  Future<List<int>?> downloadPhoto(String noteId) async {
    final token = await _token();
    final result = await apiService.getBytes(
        endpoint: ApiConstants.notePhoto(noteId), token: token);
    if (result.response.statusCode == 404) return null;
    _check(result.response);
    return result.bytes;
  }
}
