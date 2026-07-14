import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../slot/presentation/providers/game_providers.dart';
import '../../domain/entities/achievement_definition.dart';

/// One achievement's live unlocked/locked state.
class AchievementView {
  const AchievementView({required this.definition, required this.unlocked});

  final AchievementDefinition definition;
  final bool unlocked;
}

final Provider<List<AchievementView>> achievementViewsProvider = Provider<List<AchievementView>>(
  (Ref ref) {
    final game = ref.watch(gameProvider);
    return <AchievementView>[
      for (final AchievementDefinition def in AchievementDefinition.catalog)
        AchievementView(definition: def, unlocked: def.isUnlocked(game)),
    ];
  },
);
