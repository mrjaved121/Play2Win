import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/di/guest_identity_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/slots_api_client.dart';

final Provider<SlotsApiClient> slotsApiClientProvider = Provider<SlotsApiClient>(
  (Ref ref) => SlotsApiClient(),
);

const Map<SlotSymbol, String> _symbolEmoji = <SlotSymbol, String>{
  SlotSymbol.skull: '💀',
  SlotSymbol.lemon: '🍋',
  SlotSymbol.cherry: '🍒',
  SlotSymbol.bell: '🔔',
  SlotSymbol.bar: '🎰', // no single-glyph "BAR" emoji; closest readable stand-in
  SlotSymbol.coin: '🪙',
  SlotSymbol.diamond: '💎',
  SlotSymbol.luckyStar: '⭐',
  SlotSymbol.seven: '7️⃣',
};

/// Reports the grid's middle row — the classic single-payline read of a
/// slot machine — as this spin's admin-facing "outcome"/"symbols". The
/// real engine checks 5 paylines (see GameConstants.paylines), but a
/// 3-symbol summary matches what admin will expect to read; `symbols`
/// stays machine-readable (enum names) while `outcome` is a display
/// string.
({String outcome, List<String> symbols}) encodeSlotRow(List<SlotSymbol> middleRow) {
  return (
    outcome: middleRow.map((SlotSymbol s) => _symbolEmoji[s] ?? s.name).join(),
    symbols: middleRow.map((SlotSymbol s) => s.name).toList(),
  );
}

/// Best-effort bridge from a resolved local spin to blackhole_admin, so
/// admin gets the same visibility/portability Multiplier Climb already
/// has. Never blocks or alters local gameplay — see GameNotifier.
class SlotsSyncController {
  SlotsSyncController(this._ref);

  final Ref _ref;

  Future<int?> recordSpin({
    required int bet,
    required int winAmount,
    required bool isWin,
    required bool isJackpot,
    required String outcome,
    required List<String> symbols,
    required int clientBalance,
  }) {
    final String guestId = _ref.read(guestIdProvider);
    final String? accessToken = _ref.read(authRepositoryProvider)?.accessToken;
    return _ref.read(slotsApiClientProvider).recordSpin(
          guestId: guestId,
          accessToken: accessToken,
          bet: bet,
          winAmount: winAmount,
          isWin: isWin,
          isJackpot: isJackpot,
          outcome: outcome,
          symbols: symbols,
          clientBalance: clientBalance,
        );
  }
}

final Provider<SlotsSyncController> slotsSyncControllerProvider =
    Provider<SlotsSyncController>((Ref ref) => SlotsSyncController(ref));
