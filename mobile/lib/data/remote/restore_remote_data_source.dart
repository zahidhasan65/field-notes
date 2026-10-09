import '../../core/network/api_service.dart';
import '../../core/storage/session_storage.dart';

class RestoreRemoteDataSource {
  final ApiService apiService;
  final SessionStorage sessionStorage;

  RestoreRemoteDataSource({
    ApiService? apiService,
    SessionStorage? sessionStorage,
  }) : apiService = apiService ?? ApiService(),
       sessionStorage = sessionStorage ?? SessionStorage();

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await _get('/customers');

    return _extractList(response.data);
  }

  Future<List<Map<String, dynamic>>> getSites(String customerId) async {
    final response = await _get('/customers/$customerId/sites');

    return _extractList(response.data);
  }

  Future<List<Map<String, dynamic>>> getFieldNotes(String siteId) async {
    final response = await _get('/sites/$siteId/field-notes');

    return _extractList(response.data);
  }

  Future<dynamic> _get(String endpoint) async {
    final token = await sessionStorage.getToken();

    if (token == null || token.isEmpty) {
      throw StateError('Authentication token is not available.');
    }

    final response = await apiService.get(endpoint: endpoint, token: token);

    if (!response.isSuccess) {
      throw Exception(
        'Restore request failed (${response.statusCode}): '
        '${response.errorMessage ?? 'Unknown error'}',
      );
    }

    return response;
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'];

      if (content is List) {
        return content
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      final items = data['items'];

      if (items is List) {
        return items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    throw FormatException('Unexpected restore response format.');
  }
}
