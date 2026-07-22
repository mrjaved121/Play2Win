import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Slim auto-cycling "recent wins" banner shown above the lane board —
/// matches the reference UI's "Live wins" strip. Self-contained, ambient
/// visual flavor only (like Multiplier Climb's `LiveLeaderboard`/
/// `LeaderboardSeed` — there is no real cross-player feed here), so it
/// doesn't touch game state/providers at all.
class LiveWinsTicker extends StatefulWidget {
  const LiveWinsTicker({super.key});

  @override
  State<LiveWinsTicker> createState() => _LiveWinsTickerState();
}

class _LiveWinsTickerState extends State<LiveWinsTicker> {
  static const List<String> _names = <String>[
    'Ali_K', 'Zara99', 'Ahmed.R', 'Nimra_Q', 'Bilal7', 'Sana_M', 'Usman_X', 'Hina.T', 'Faisal22', 'Ayesha_N',
  ];
  static const List<int> _bets = <int>[20, 50, 100, 250, 500];

  final Random _random = Random();
  late Timer _timer;
  late (String name, int bet, double multiplier) _current;

  @override
  void initState() {
    super.initState();
    _current = _roll();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() => _current = _roll());
    });
  }

  (String name, int bet, double multiplier) _roll() {
    final String name = _names[_random.nextInt(_names.length)];
    final int bet = _bets[_random.nextInt(_bets.length)];
    final double multiplier = 1.05 + _random.nextDouble() * _random.nextDouble() * 15;
    return (name, bet, multiplier);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int winAmount = (_current.$2 * _current.$3).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('LIVE WINS', style: AppTextStyles.label),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                '${_current.$1} +$winAmount CR (${_current.$3.toStringAsFixed(2)}x)',
                key: ValueKey<String>('${_current.$1}$winAmount'),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
