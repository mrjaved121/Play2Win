import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../domain/entities/purchase_info.dart';

const String _purchaseInfoKey = 'purchase_instructions';

/// Talks to blackhole_admin's public `/api/public/app-content/[key]` route
/// — no login, same as Help & Support.
class PurchaseInfoApiClient {
  PurchaseInfoApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  /// Null if nothing has been published (or the backend isn't reachable) —
  /// never throws, since this is display-only content, not gameplay-
  /// critical.
  Future<PurchaseInfo?> fetch() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/api/public/app-content/$_purchaseInfoKey'))
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic>? content = json['content'] as Map<String, dynamic>?;
      return content != null ? PurchaseInfo.fromJson(content) : null;
    } catch (_) {
      return null;
    }
  }
}
