/// One real wallet transaction, persisted locally (see
/// `WalletTransactionsNotifier`) — recorded live as bets are placed,
/// spins pay out and the daily bonus is claimed, not mock data.
enum TransactionType { win, purchase, bonus, loss }

class WalletTransaction {
  const WalletTransaction({
    required this.type,
    required this.label,
    required this.amount,
    required this.timestamp,
  });

  final TransactionType type;
  final String label;
  final int amount;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'label': label,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        type: TransactionType.values.byName(json['type'] as String),
        label: json['label'] as String,
        amount: json['amount'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  /// Relative time, e.g. "5 min ago" — computed at display time rather
  /// than frozen as a string, so a wallet screen left open stays accurate.
  String get timeAgoLabel {
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
