import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Last Win / Best Win Today / Games Played, in a row on wide screens or
/// wrapped in a compact grid on narrow phones.
class StatsRow extends StatelessWidget {
  const StatsRow({
    required this.lastWin,
    required this.bestWinToday,
    required this.gamesPlayed,
    super.key,
  });

  final int lastWin;
  final int bestWinToday;
  final int gamesPlayed;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = <Widget>[
      StatTile(label: 'Last Win', value: '$lastWin', icon: Icons.monetization_on_rounded),
      StatTile(label: 'Best Win Today', value: '$bestWinToday', icon: Icons.monetization_on_rounded),
      StatTile(label: 'Games Played', value: '$gamesPlayed', icon: Icons.casino_rounded),
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          Expanded(child: tiles[i]),
          if (i != tiles.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}
