import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';

class PurchaseInfoApiException implements Exception {
  PurchaseInfoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to blackhole_admin's public `/api/public/purchase-guides` route —
/// no login, same "Guest Mode" spirit as the rest of this app.
class PurchaseInfoApiClient {
  PurchaseInfoApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  Future<List<Map<String, dynamic>>> fetchGuides() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/public/purchase-guides'))
          .timeout(_timeout);
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw PurchaseInfoApiException('Unexpected response from server');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PurchaseInfoApiException(json['error'] as String? ?? 'Server error (${response.statusCode})');
      }
      return (json['guides'] as List<dynamic>).cast<Map<String, dynamic>>();
    } on PurchaseInfoApiException {
      rethrow;
    } catch (_) {
      throw PurchaseInfoApiException("Can't reach the server");
    }
  }
}
