import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../domain/entities/wheel_result.dart';

class WheelApiException implements Exception {
  WheelApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to blackhole_admin's `/api/games/wheel/play` — server decides the
/// outcome; this is a plain request/response call, no local RNG.
class WheelApiClient {
  WheelApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  Future<WheelPlayResult> spin({required String guestId, String? accessToken, required int bet}) async {
    try {
      final http.Response response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/games/wheel/play'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(<String, dynamic>{'guestId': guestId, 'bet': bet}),
          )
          .timeout(_timeout);
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw WheelApiException('Unexpected response from game server');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WheelApiException(json['error'] as String? ?? 'Game server error (${response.statusCode})');
      }
      return WheelPlayResult.fromJson(json);
    } on WheelApiException {
      rethrow;
    } catch (_) {
      throw WheelApiException("Can't reach the game server");
    }
  }

  /// This player's past spins, most recent first — powers the history
  /// strip. Called once when the wheel screen loads, same convention as
  /// the crash game's history fetch.
  Future<List<WheelHistoryEntry>> fetchHistory(String guestId, {String? accessToken}) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/games/wheel/history')
        .replace(queryParameters: <String, String>{'guestId': guestId, 'pageSize': '20'});
    final http.Response response = await _client
        .get(
          uri,
          headers: <String, String>{if (accessToken != null) 'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_timeout);
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WheelApiException('Unexpected response from game server');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WheelApiException(json['error'] as String? ?? 'Game server error (${response.statusCode})');
    }
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];
    return <WheelHistoryEntry>[
      for (final dynamic item in items) WheelHistoryEntry.fromJson(item as Map<String, dynamic>),
    ];
  }
}
