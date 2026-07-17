/// One resolved wheel spin — the server already decided everything
/// (segmentIndex/multiplier/winAmount); this is just the response shape.
class WheelPlayResult {
  const WheelPlayResult({
    required this.segmentIndex,
    required this.multiplier,
    required this.winAmount,
    required this.newBalance,
  });

  final int segmentIndex;
  final double multiplier;
  final int winAmount;
  final int newBalance;

  factory WheelPlayResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> result = json['result'] as Map<String, dynamic>;
    return WheelPlayResult(
      segmentIndex: result['segmentIndex'] as int,
      multiplier: (result['multiplier'] as num).toDouble(),
      winAmount: (json['winAmount'] as num).toInt(),
      newBalance: (json['newBalance'] as num).toInt(),
    );
  }
}

/// One past spin from the player's server-side history — backs the wheel
/// screen's history strip. Lighter than [WheelPlayResult]: history only
/// needs the outcome, not `newBalance`.
class WheelHistoryEntry {
  const WheelHistoryEntry({
    required this.bet,
    required this.multiplier,
    required this.winAmount,
    required this.isWin,
    required this.timestamp,
  });

  final int bet;
  final double multiplier;
  final int winAmount;
  final bool isWin;
  final DateTime timestamp;

  factory WheelHistoryEntry.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> result = json['result'] as Map<String, dynamic>;
    final int winAmount = (json['winAmount'] as num).toInt();
    return WheelHistoryEntry(
      bet: (json['betAmount'] as num).toInt(),
      multiplier: (result['multiplier'] as num).toDouble(),
      winAmount: winAmount,
      isWin: winAmount > 0,
      timestamp: DateTime.parse(json['createdAt'] as String),
    );
  }
}
