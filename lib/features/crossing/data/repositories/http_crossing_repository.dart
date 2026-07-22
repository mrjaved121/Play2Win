import '../../domain/entities/crossing_round.dart';
import '../../domain/repositories/crossing_repository.dart';
import '../datasources/crossing_api_client.dart';

class HttpCrossingRepository implements CrossingRepository {
  HttpCrossingRepository(this._client);

  final CrossingApiClient _client;

  @override
  Future<({int balance, String? playerId})> fetchBalance(String guestId, {String? accessToken}) =>
      _client.fetchBalance(guestId, accessToken: accessToken);

  @override
  Future<CrossingRoundResult> placeBet({
    required String guestId,
    required int betAmount,
    required CrossingDifficulty difficulty,
    required String clientSeed,
    String? accessToken,
  }) async {
    final Map<String, dynamic> json = await _client.placeBet(
      guestId: guestId,
      betAmount: betAmount,
      difficulty: difficulty,
      clientSeed: clientSeed,
      accessToken: accessToken,
    );
    return CrossingRoundResult.fromJson(json);
  }

  @override
  Future<CrossingRoundResult> advance({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) async {
    final Map<String, dynamic> json = await _client.advance(
      guestId: guestId,
      roundId: roundId,
      accessToken: accessToken,
    );
    return CrossingRoundResult.fromJson(json);
  }

  @override
  Future<CrossingRoundResult> cashout({
    required String guestId,
    required String roundId,
    String? accessToken,
  }) async {
    final Map<String, dynamic> json = await _client.cashout(
      guestId: guestId,
      roundId: roundId,
      accessToken: accessToken,
    );
    return CrossingRoundResult.fromJson(json);
  }

  @override
  Future<CrossingRound?> fetchState({
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
    return CrossingRound.fromJson(json['round'] as Map<String, dynamic>);
  }

  @override
  Future<void> linkAccount({required String guestId, required String accessToken}) {
    return _client.linkAccount(guestId: guestId, accessToken: accessToken);
  }

  @override
  Future<List<CrossingHistoryEntry>> fetchHistory(String guestId, {String? accessToken}) async {
    final Map<String, dynamic> json = await _client.fetchHistory(guestId, accessToken: accessToken);
    final List<dynamic> items = json['items'] as List<dynamic>? ?? <dynamic>[];
    return <CrossingHistoryEntry>[
      for (final dynamic item in items) CrossingHistoryEntry.fromJson(item as Map<String, dynamic>),
    ];
  }
}
