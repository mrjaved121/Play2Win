/// One resolved scratch card — the server already decided everything
/// (tier/multiplier/winAmount/panels); this is just the response shape.
class ScratchPlayResult {
  const ScratchPlayResult({
    required this.multiplier,
    required this.winAmount,
    required this.panels,
    required this.newBalance,
  });

  final double multiplier;
  final int winAmount;

  /// 3 symbols to reveal — all matching on a win, guaranteed non-matching
  /// on a loss. Purely cosmetic; the prize was already decided server-side.
  final List<String> panels;
  final int newBalance;

  factory ScratchPlayResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> result = json['result'] as Map<String, dynamic>;
    return ScratchPlayResult(
      multiplier: (result['multiplier'] as num).toDouble(),
      winAmount: (json['winAmount'] as num).toInt(),
      panels: (result['panels'] as List<dynamic>).cast<String>(),
      newBalance: (json['newBalance'] as num).toInt(),
    );
  }
}

/// One past card from the player's server-side history — backs the
/// scratch screen's history strip. Lighter than [ScratchPlayResult]:
/// history only needs the outcome, not `newBalance`/`panels`.
class ScratchHistoryEntry {
  const ScratchHistoryEntry({
    required this.cost,
    required this.multiplier,
    required this.winAmount,
    required this.isWin,
    required this.timestamp,
  });

  final int cost;
  final double multiplier;
  final int winAmount;
  final bool isWin;
  final DateTime timestamp;

  factory ScratchHistoryEntry.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> result = json['result'] as Map<String, dynamic>;
    final int winAmount = (json['winAmount'] as num).toInt();
    return ScratchHistoryEntry(
      cost: (json['betAmount'] as num).toInt(),
      multiplier: (result['multiplier'] as num).toDouble(),
      winAmount: winAmount,
      isWin: winAmount > 0,
      timestamp: DateTime.parse(json['createdAt'] as String),
    );
  }
}
