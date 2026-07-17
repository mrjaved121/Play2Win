import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';

/// Talks to blackhole_admin's `/api/slots/spin` — purely a fire-and-forget
/// audit/balance-sync call from the game's perspective (see
/// SlotsSyncController). Every failure mode returns null rather than
/// throwing, since a network hiccup here must never surface to the player
/// or interrupt a spin that has already resolved locally.
class SlotsApiClient {
  SlotsApiClient({http.Client? client, this._timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration _timeout;

  /// Returns the authoritative new balance, or null on any failure
  /// (unconfigured backend, network error, non-2xx response).
  Future<int?> recordSpin({
    required String guestId,
    String? accessToken,
    required int bet,
    required int winAmount,
    required bool isWin,
    required bool isJackpot,
    required String outcome,
    required List<String> symbols,
    required int clientBalance,
  }) async {
    try {
      final http.Response response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/slots/spin'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(<String, dynamic>{
              'guestId': guestId,
              'bet': bet,
              'winAmount': winAmount,
              'isWin': isWin,
              'isJackpot': isJackpot,
              'outcome': outcome,
              'symbols': symbols,
              'clientBalance': clientBalance,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['balance'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }
}
