import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../domain/entities/scratch_result.dart';

class ScratchApiException implements Exception {
  ScratchApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to blackhole_admin's `/api/games/scratch/play` — server decides
/// the prize; this is a plain request/response call, no local RNG.
class ScratchApiClient {
  ScratchApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  Future<ScratchPlayResult> play({required String guestId, String? accessToken, required int cost}) async {
    try {
      final http.Response response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/games/scratch/play'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(<String, dynamic>{'guestId': guestId, 'bet': cost}),
          )
          .timeout(_timeout);
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ScratchApiException('Unexpected response from game server');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ScratchApiException(json['error'] as String? ?? 'Game server error (${response.statusCode})');
      }
      return ScratchPlayResult.fromJson(json);
    } on ScratchApiException {
      rethrow;
    } catch (_) {
      throw ScratchApiException("Can't reach the game server");
    }
  }

  /// This player's past cards, most recent first — powers the history
  /// strip. Called once when the scratch screen loads, same convention as
  /// the crash game's history fetch.
  Future<List<ScratchHistoryEntry>> fetchHistory(String guestId, {String? accessToken}) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/games/scratch/history')
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
      throw ScratchApiException('Unexpected response from game server');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ScratchApiException(json['error'] as String? ?? 'Game server error (${response.statusCode})');
    }
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];
    return <ScratchHistoryEntry>[
      for (final dynamic item in items) ScratchHistoryEntry.fromJson(item as Map<String, dynamic>),
    ];
  }
}
