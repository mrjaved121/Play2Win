import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/crossing_providers.dart';
import 'crossing_history_modal.dart';
import 'crossing_how_to_play_dialog.dart';
import 'crossing_provably_fair_sheet.dart';
import 'crossing_rules_dialog.dart';

/// Hamburger menu sheet — Sound/Music toggles plus the four reference-UI
/// actions (Provably fair settings, Game rules, My bet history, How to
/// play), matching the screenshots' menu layout.
void showCrossingMenuSheet(BuildContext context, CrossingSharedState state) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _CrossingMenuSheet(state: state),
  );
}

class _CrossingMenuSheet extends StatefulWidget {
  const _CrossingMenuSheet({required this.state});

  final CrossingSharedState state;

  @override
  State<_CrossingMenuSheet> createState() => _CrossingMenuSheetState();
}

class _CrossingMenuSheetState extends State<_CrossingMenuSheet> {
  late bool _sound = getIt<AudioService>().isSfxEnabled;
  late bool _music = getIt<AudioService>().isMusicEnabled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        color: AppColors.backgroundElevated,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: const BoxDecoration(color: AppColors.cardBorder, borderRadius: AppRadius.radiusPill),
            ),
            SettingsToggleRow(
              icon: Icons.volume_up_rounded,
              label: 'Sound',
              value: _sound,
              onChanged: (bool v) {
                setState(() => _sound = v);
                getIt<AudioService>().setSfxEnabled(v);
              },
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.cardBorder),
            SettingsToggleRow(
              icon: Icons.music_note_rounded,
              label: 'Music',
              value: _music,
              onChanged: (bool v) {
                setState(() => _music = v);
                getIt<AudioService>().setMusicEnabled(v);
              },
            ),
            const Divider(height: AppSpacing.xl, color: AppColors.cardBorder),
            SettingsNavRow(
              icon: Icons.verified_user_rounded,
              label: 'Provably fair settings',
              onTap: () {
                Navigator.of(context).pop();
                showCrossingProvablyFairSheet(context);
              },
            ),
            SettingsNavRow(
              icon: Icons.rule_rounded,
              label: 'Game rules',
              onTap: () {
                Navigator.of(context).pop();
                showCrossingRulesDialog(context, widget.state);
              },
            ),
            SettingsNavRow(
              icon: Icons.history_rounded,
              label: 'My bet history',
              onTap: () {
                Navigator.of(context).pop();
                showCrossingHistoryModal(context, widget.state);
              },
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.cardBorder),
            SettingsNavRow(
              icon: Icons.help_outline_rounded,
              label: 'How to play?',
              onTap: () {
                Navigator.of(context).pop();
                showCrossingHowToPlayDialog(context, widget.state);
              },
            ),
          ],
        ),
      ),
    );
  }
}
