import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';

/// Thrown for both HTTP-level failures (non-2xx, unparsable body) and
/// network-level failures (timeout, no connection) so callers only ever
/// have one exception type to catch.
class CrashApiException implements Exception {
  CrashApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to blackhole_admin's `/api/games/crash/*` routes. Every method
/// here is a plain request/response call — see [[CrashSlotNotifier]] for
/// how the climbing multiplier is rendered locally between these calls
/// instead of polling for it.
class CrashApiClient {
  CrashApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
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
      throw CrashApiException('Unexpected response from game server');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    throw CrashApiException(json['error'] as String? ?? 'Game server error (${response.statusCode})');
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
    } on CrashApiException {
      rethrow;
    } catch (_) {
      throw CrashApiException("Can't reach the game server");
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
    } on CrashApiException {
      rethrow;
    } catch (_) {
      throw CrashApiException("Can't reach the game server");
    }
  }

  /// [accessToken], when the player is signed in, makes the server resolve
  /// balance/rounds by account instead of this device's [guestId] — see
  /// blackhole_admin's CrashRepository.resolvePlayer. The returned
  /// `playerId` is the canonical `players.id` row admin sees in the
  /// dashboard — a different value from [guestId], which is only the
  /// device-local lookup key.
  Future<({int balance, String? playerId})> fetchBalance(String guestId, {String? accessToken}) async {
    final Map<String, dynamic> json = await _get(
      '/api/games/crash/balance',
      <String, String>{'guestId': guestId},
      accessToken: accessToken,
    );
    return (balance: (json['balance'] as num).toInt(), playerId: json['playerId'] as String?);
  }

  Future<Map<String, dynamic>> placeBet({
    required String guestId,
    required int betAmount,
    String? accessToken,
  }) {
    return _post(
      '/api/games/crash/bet',
      <String, dynamic>{'guestId': guestId, 'betAmount': betAmount},
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> collect({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) {
    return _post(
      '/api/games/crash/collect',
      <String, dynamic>{'guestId': guestId, 'roundId': roundId},
      accessToken: accessToken,
    );
  }

  /// Returns null on a 404 (round not found) rather than throwing —
  /// that's an expected, non-exceptional outcome for this endpoint.
  Future<Map<String, dynamic>?> fetchState({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) async {
    try {
      final http.Response response = await _client
          .get(
            _uri('/api/games/crash/state', <String, String>{'guestId': guestId, 'roundId': roundId}),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);
      if (response.statusCode == 404) return null;
      return _decode(response);
    } on CrashApiException {
      rethrow;
    } catch (_) {
      throw CrashApiException("Can't reach the game server");
    }
  }

  /// This player's past resolved rounds, most recent first — powers the
  /// round history strip. Called once when the crash screen loads rather
  /// than after every round, since this session's own rounds are already
  /// appended locally as they resolve (see [[CrashSlotNotifier]]).
  Future<Map<String, dynamic>> fetchHistory(String guestId, {String? accessToken}) {
    return _get(
      '/api/games/crash/history',
      <String, String>{'guestId': guestId, 'pageSize': '20'},
      accessToken: accessToken,
    );
  }

  /// Links this device's guest player row to the caller's verified account
  /// (identified server-side from [accessToken], not [guestId] alone) so
  /// admin can find/credit a real account instead of an anonymous guest.
  /// Hits `/api/public/players/link` rather than `/api/games/crash/*`, but
  /// lives here since it's the crash player row being linked and reuses
  /// this client's HTTP/error-handling plumbing.
  Future<void> linkAccount({required String guestId, required String accessToken}) {
    return _post(
      '/api/public/players/link',
      <String, dynamic>{'guestId': guestId},
      accessToken: accessToken,
    );
  }

  /// Platform-wide activity (not per-player) — hits `/api/public/crash/*`
  /// rather than `/api/games/crash/*` since it's the same response for
  /// every caller, no guestId/accessToken involved.
  Future<Map<String, dynamic>> fetchLeaderboard() {
    return _get('/api/public/crash/leaderboard', const <String, String>{});
  }
}
