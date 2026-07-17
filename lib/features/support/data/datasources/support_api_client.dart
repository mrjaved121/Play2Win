import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';

class SupportApiException implements Exception {
  SupportApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to blackhole_admin's public `/api/public/news` route — no login,
/// same "Guest Mode" spirit as the rest of this app.
class SupportApiClient {
  SupportApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  Future<List<Map<String, dynamic>>> fetchEntries() async {
    try {
      final http.Response response =
          await _client.get(Uri.parse('${ApiConfig.baseUrl}/api/public/news')).timeout(_timeout);
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw SupportApiException('Unexpected response from support server');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SupportApiException(json['error'] as String? ?? 'Support server error (${response.statusCode})');
      }
      return (json['news'] as List<dynamic>).cast<Map<String, dynamic>>();
    } on SupportApiException {
      rethrow;
    } catch (_) {
      throw SupportApiException("Can't reach the support server");
    }
  }
}
