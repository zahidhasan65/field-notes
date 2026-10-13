import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import 'api_response.dart';

class ApiService {
  Future<ApiResponse> post({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) =>
      _sendJson('POST', endpoint, body: body, token: token);

  Future<ApiResponse> get({required String endpoint, String? token}) =>
      _sendJson('GET', endpoint, token: token);

  Future<ApiResponse> put({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
  }) =>
      _sendJson('PUT', endpoint, body: body, token: token);

  Future<ApiResponse> delete({required String endpoint, String? token}) =>
      _sendJson('DELETE', endpoint, token: token);

  Future<ApiResponse> postFile({
    required String endpoint,
    required String filePath,
    String fieldName = 'file',
    required String token,
  }) async {
    final uploadTimeout = ApiConstants.timeout * 3;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        contentType: _mediaTypeFor(filePath),
      ));

      final streamed = await request.send().timeout(uploadTimeout);

      final response =
      await http.Response.fromStream(streamed).timeout(uploadTimeout);
      return _toApiResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  Future<({ApiResponse response, List<int>? bytes})> getBytes({
    required String endpoint,
    required String token,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      )
          .timeout(ApiConstants.timeout * 3);

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      return (
      response: ApiResponse(
        isSuccess: ok,
        statusCode: response.statusCode,
        errorMessage: ok ? null : 'Download failed (${response.statusCode}).',
      ),
      bytes: ok ? response.bodyBytes : null,
      );
    } catch (e) {
      return (response: _networkError(e), bytes: null);
    }
  }

  Future<ApiResponse> _sendJson(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    try {
      final request = http.Request(
        method,
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamed = await request.send().timeout(ApiConstants.timeout);

      final response = await http.Response.fromStream(streamed)
          .timeout(ApiConstants.timeout);
      return _toApiResponse(response);
    } catch (e) {
      return _networkError(e);
    }
  }

  ApiResponse _toApiResponse(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = response.body;
      }
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      debugPrint('API ${response.statusCode} ${response.request?.url}: '
          '${response.body}');
    }
    return ApiResponse(
      isSuccess: ok,
      statusCode: response.statusCode,
      data: data,
      errorMessage: ok ? null : _extractErrorMessage(data),
    );
  }


  ApiResponse _networkError(Object e) {
    debugPrint('API error: $e');
    final unreachable = e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException;

    return ApiResponse(
      isSuccess: false,
      statusCode: unreachable ? 0 : -1,
      errorMessage: unreachable
          ? 'Cannot reach the server. Check your internet connection.'
          : e.toString(),
    );
  }

  MediaType _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    return MediaType('image', 'jpeg');
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