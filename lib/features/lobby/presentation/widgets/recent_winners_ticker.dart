import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';

/// Auto-scrolling "recent winners" strip above the promo carousel — same
/// realistic-mock-data approach the app already uses for the Home
/// screen's [[PromoTicker]] and the Leaderboard's mock field (there's no
/// live multiplayer backend to source real other players from), just
/// applied across a scrolling row instead of one fixed line. Coins only,
/// no real-money implication.
class RecentWinnersTicker extends StatefulWidget {
  const RecentWinnersTicker({super.key});

  @override
  State<RecentWinnersTicker> createState() => _RecentWinnersTickerState();
}

class _RecentWinnersTickerState extends State<RecentWinnersTicker> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;

  static const double _cardExtent = 172;

  static const List<(String name, int coins)> _mockWinners = <(String, int)>[
    ('ShadowWolf99', 480),
    ('LuckyStrike', 1250),
    ('SpinQueen', 320),
    ('GoldRush88', 2100),
    ('CoinCollector', 610),
    ('NightOwlSpins', 890),
    ('ReelDeal', 175),
    ('FortuneFinder', 3400),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    final double max = _controller.position.maxScrollExtent;
    final double next = _controller.offset + _cardExtent;
    unawaited(
      _controller.animateTo(
        next > max ? 0 : next,
        duration: AppConstants.animNormal,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _mockWinners.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int i) {
          final (String name, int coins) = _mockWinners[i];
          return _WinnerCard(name: name, coins: coins);
        },
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.name, required this.coins});

  final String name;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _RecentWinnersTickerState._cardExtent - AppSpacing.sm,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: AppGradients.glass,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '+${coins.asGrouped} coins',
                  style: AppTextStyles.label.copyWith(color: AppColors.success, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
