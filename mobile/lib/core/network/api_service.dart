import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_response.dart';

class ApiService {
  Future<ApiResponse> post({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    return _sendRequest(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      token: token,
    );
  }

  Future<ApiResponse> get({
    required String endpoint,
    String? token,
  }) async {
    return _sendRequest(
      method: 'GET',
      endpoint: endpoint,
      token: token,
    );
  }
  Future<ApiResponse> put({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    return _sendRequest(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      token: token,
    );
  }

  Future<ApiResponse> delete({
    required String endpoint,
    String? token,
  }) async {
    return _sendRequest(
      method: 'DELETE',
      endpoint: endpoint,
      token: token,
    );
  }

  Future<ApiResponse> _sendRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final request = http.Request(
        method,
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      );

      request.headers.addAll(headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      dynamic responseData;

      if (response.body.isNotEmpty) {
        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          responseData = response.body;
        }
      }

      final isSuccess =
          response.statusCode >= 200 && response.statusCode < 300;

      return ApiResponse(
        isSuccess: isSuccess,
        statusCode: response.statusCode,
        data: responseData,
        errorMessage:
            isSuccess ? null : _extractErrorMessage(responseData),
      );
    } catch (e) {
      return ApiResponse(
        isSuccess: false,
        statusCode: 0,
        errorMessage: e.toString(),
      );
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

