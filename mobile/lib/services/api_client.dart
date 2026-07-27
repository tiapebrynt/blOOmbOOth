import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Wrapper sederhana di atas package `http`. Aplikasi ini tidak memakai
/// login/register, jadi tidak ada header Authorization/token di sini —
/// semua request langsung ditujukan ke backend tanpa autentikasi.
class ApiClient {
  static const _headers = {'Content-Type': 'application/json'};

  static Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      body['message'] ?? 'Terjadi kesalahan tak terduga',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('${AppConstants.baseUrl}$path'), headers: _headers);
    return _handle(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(Uri.parse('${AppConstants.baseUrl}$path'), headers: _headers);
    return _handle(res);
  }

  // Upload multipart untuk file foto hasil jepretan Live Camera / stiker custom
  static Future<Map<String, dynamic>> uploadImage(String path, String filePath) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        filePath,
        contentType: MediaType('image', 'jpeg'),
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handle(response);
  }
}
