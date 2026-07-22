import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../domain/entities/crossing_round.dart';

/// Thrown for both HTTP-level failures (non-2xx, unparsable body) and
/// network-level failures (timeout, no connection) so callers only ever
/// have one exception type to catch — mirrors [CrashApiException].
class CrossingApiException implements Exception {
  CrossingApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to blackhole_admin's `/api/games/crossing/*` routes. Mirrors
/// `CrashApiClient` file-for-file except for the extra [difficulty]/
/// [clientSeed] on [placeBet] and the new [advance]/[cashout] pair in place
/// of crash's single `collect`.
class CrossingApiClient {
  CrossingApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw CrossingApiException('Unexpected response from game server');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    throw CrossingApiException(json['error'] as String? ?? 'Game server error (${response.statusCode})');
  }

  Map<String, String> _headers(String? accessToken, {bool json = false}) {
    return <String, String>{
      if (json) 'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query, {
    String? accessToken,
  }) async {
    try {
      final http.Response response =
          await _client.get(_uri(path, query), headers: _headers(accessToken)).timeout(_timeout);
      return _decode(response);
    } on CrossingApiException {
      rethrow;
    } catch (_) {
      throw CrossingApiException("Can't reach the game server");
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? accessToken,
  }) async {
    try {
      final http.Response response = await _client
          .post(_uri(path), headers: _headers(accessToken, json: true), body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(response);
    } on CrossingApiException {
      rethrow;
    } catch (_) {
      throw CrossingApiException("Can't reach the game server");
    }
  }

  Future<({int balance, String? playerId})> fetchBalance(String guestId, {String? accessToken}) async {
    final Map<String, dynamic> json = await _get(
      '/api/games/crossing/balance',
      <String, String>{'guestId': guestId},
      accessToken: accessToken,
    );
    return (balance: (json['balance'] as num).toInt(), playerId: json['playerId'] as String?);
  }

  Future<Map<String, dynamic>> placeBet({
    required String guestId,
    required int betAmount,
    required CrossingDifficulty difficulty,
    required String clientSeed,
    String? accessToken,
  }) {
    return _post(
      '/api/games/crossing/bet',
      <String, dynamic>{
        'guestId': guestId,
        'betAmount': betAmount,
        'difficulty': difficulty.name,
        'clientSeed': clientSeed,
      },
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> advance({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) {
    return _post(
      '/api/games/crossing/advance',
      <String, dynamic>{'guestId': guestId, 'roundId': roundId},
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> cashout({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) {
    return _post(
      '/api/games/crossing/cashout',
      <String, dynamic>{'guestId': guestId, 'roundId': roundId},
      accessToken: accessToken,
    );
  }

  /// Returns null on a 404 (round not found) rather than throwing — that's
  /// an expected, non-exceptional outcome for this endpoint.
  Future<Map<String, dynamic>?> fetchState({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) async {
    try {
      final http.Response response = await _client
          .get(
            _uri('/api/games/crossing/state', <String, String>{'guestId': guestId, 'roundId': roundId}),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);
      if (response.statusCode == 404) return null;
      return _decode(response);
    } on CrossingApiException {
      rethrow;
    } catch (_) {
      throw CrossingApiException("Can't reach the game server");
    }
  }

  Future<Map<String, dynamic>> fetchHistory(String guestId, {String? accessToken}) {
    return _get(
      '/api/games/crossing/history',
      <String, String>{'guestId': guestId, 'pageSize': '20'},
      accessToken: accessToken,
    );
  }

  /// Links this device's guest player row to the caller's verified account
  /// — same shared `players` row crash's `linkAccount` promotes.
  Future<void> linkAccount({required String guestId, required String accessToken}) {
    return _post(
      '/api/public/players/link',
      <String, dynamic>{'guestId': guestId},
      accessToken: accessToken,
    );
  }

  /// Platform-wide activity (not per-player) — hits `/api/public/crossing/*`
  /// rather than `/api/games/crossing/*` since it's the same response for
  /// every caller, no guestId/accessToken involved.
  Future<Map<String, dynamic>> fetchLeaderboard() {
    return _get('/api/public/crossing/leaderboard', const <String, String>{});
  }

  /// Live min/max/maxWin bet and the full per-difficulty payout ladder, as
  /// currently set from the admin dashboard.
  Future<Map<String, dynamic>> fetchSettings() {
    return _get('/api/public/crossing/settings', const <String, String>{});
  }
}
