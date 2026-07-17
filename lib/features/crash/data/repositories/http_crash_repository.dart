import '../../domain/entities/crash_round.dart';
import '../../domain/repositories/crash_repository.dart';
import '../datasources/crash_api_client.dart';

class HttpCrashRepository implements CrashRepository {
  HttpCrashRepository(this._client);

  final CrashApiClient _client;

  @override
  Future<({int balance, String? playerId})> fetchBalance(String guestId, {String? accessToken}) =>
      _client.fetchBalance(guestId, accessToken: accessToken);

  @override
  Future<CrashRoundResult> placeBet({
    required String guestId,
    required int betAmount,
    String? accessToken,
  }) async {
    final Map<String, dynamic> json = await _client.placeBet(
      guestId: guestId,
      betAmount: betAmount,
      accessToken: accessToken,
    );
    return CrashRoundResult.fromJson(json);
  }

  @override
  Future<CrashRoundResult> collect({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) async {
    final Map<String, dynamic> json = await _client.collect(
      guestId: guestId,
      roundId: roundId,
      accessToken: accessToken,
    );
    return CrashRoundResult.fromJson(json);
  }

  @override
  Future<CrashRound?> fetchState({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) async {
    final Map<String, dynamic>? json = await _client.fetchState(
      guestId: guestId,
      roundId: roundId,
      accessToken: accessToken,
    );
    if (json == null) return null;
    return CrashRound.fromJson(json['round'] as Map<String, dynamic>);
  }

  @override
  Future<void> linkAccount({required String guestId, required String accessToken}) {
    return _client.linkAccount(guestId: guestId, accessToken: accessToken);
  }

  @override
  Future<List<CrashHistoryEntry>> fetchHistory(String guestId, {String? accessToken}) async {
    final Map<String, dynamic> json = await _client.fetchHistory(guestId, accessToken: accessToken);
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];
    return <CrashHistoryEntry>[
      for (final dynamic item in items) CrashHistoryEntry.fromJson(item as Map<String, dynamic>),
    ];
  }
}
