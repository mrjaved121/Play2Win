import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/game_catalog_entry.dart';

/// Opens a bottom sheet that filters [catalog] by title as the player
/// types, matching the bet-options sheet's presentation
/// (`showModalBottomSheet` + rounded top + drag handle).
Future<void> showGameSearchSheet(
  BuildContext context, {
  required List<GameCatalogEntry> catalog,
  required ValueChanged<GameCatalogEntry> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => GameSearchSheet(catalog: catalog, onSelect: onSelect),
  );
}

class GameSearchSheet extends StatefulWidget {
  const GameSearchSheet({required this.catalog, required this.onSelect, super.key});

  final List<GameCatalogEntry> catalog;
  final ValueChanged<GameCatalogEntry> onSelect;

  @override
  State<GameSearchSheet> createState() => _GameSearchSheetState();
}

class _GameSearchSheetState extends State<GameSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<GameCatalogEntry> results = widget.catalog
        .where((GameCatalogEntry e) => e.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: AppRadius.radiusPill,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            onChanged: (String value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search games',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardPurple,
              border: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.radiusMd,
                borderSide: BorderSide(color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Text(
                      'No games match "$_query"',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (BuildContext context, int i) {
                      final GameCatalogEntry entry = results[i];
                      return PressableScale(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSelect(entry);
                        },
                        child: PremiumCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: entry.accentColor.withValues(alpha: entry.isLive ? 1 : 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(entry.icon, size: 20, color: AppColors.textOnGold),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(entry.title, style: AppTextStyles.bodyMedium),
                              ),
                              entry.isLive
                                  ? const BadgePill(label: 'PLAY', color: AppColors.gold, filled: true)
                                  : const BadgePill(
                                      label: 'SOON',
                                      icon: Icons.lock_rounded,
                                      color: AppColors.textMuted,
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
