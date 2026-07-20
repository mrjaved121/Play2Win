import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flame/game.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../rewards/presentation/providers/daily_bonus_providers.dart';
import '../../../wallet/domain/entities/wallet_transaction.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../wallet/presentation/widgets/buy_credits_sheet.dart';
import '../../domain/entities/game_state.dart';
import '../../game/coin_explosion_game.dart';
import '../../game/slot_machine_controller.dart';
import '../providers/game_providers.dart';
import '../widgets/bet_controls.dart';
import '../widgets/coin_explosion_overlay.dart';
import '../widgets/compact_stats_bar.dart';
import '../widgets/daily_bonus_card.dart';
import '../widgets/floating_win_text.dart';
import '../widgets/home_header.dart';
import '../widgets/jackpot_banner.dart';
import '../widgets/low_balance_sheet.dart';
import '../widgets/near_miss_banner.dart';
import '../widgets/promo_ticker.dart';
import '../widgets/quick_status_row.dart';
import '../widgets/reel_frame.dart';
import '../widgets/spin_bar.dart';
import '../widgets/stats_row.dart';
import '../widgets/top_wins_panel.dart';
import '../widgets/win_streak_card.dart';

/// The main game screen: header, the slot machine itself, bet controls.
///
/// The reel is the one thing that must never scroll out of view while
/// playing, so this screen deliberately does *not* wrap its body in a
/// scroll view on phones — every section around the reel (header, quick
/// status pills, compact stats, spin bar) is fixed-height, and the reel
/// itself sits in the `Expanded` remainder, sized to fit whatever space
/// is left. Secondary content that doesn't fit (Double Bet, Auto Spin)
/// lives behind a "Bet Options" sheet instead of pushing the reel around.
/// On tablet/web (`_buildExpandedBody`), there's room for the fuller
/// cards in independently-scrollable side columns — the center reel
/// column still never scrolls.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late final SlotMachineController _slotController = SlotMachineController(vsync: this);
  final CoinExplosionGame _coinGame = CoinExplosionGame();
  late final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));

  bool _soundOn = true;
  bool _turboOn = false;
  Set<(int, int)> _winningCells = <(int, int)>{};
  bool _hasWin = false;
  bool _showNearMiss = false;
  bool _showJackpot = false;
  int _shakeTrigger = 0;
  int? _floatingWinAmount;

  bool _autoSpinActive = false;
  int _autoSpinStopAfter = AppConstants.autoSpinOptions.first;
  int _autoSpinRemaining = 0;

  static const List<(String name, int coins, int vipTier)> _mockTopWinners = <(String, int, int)>[
    ('ShadowWolf99', 410, 3),
    ('MegaWinner22', 394, 2),
    ('LuckyStrike', 393, 1),
    ('SpinQueen', 364, 1),
  ];

  /// Re-ranked live against the player's actual balance rather than
  /// pinned at a fixed spot.
  List<TopWinEntry> _topWins(int myBalance) {
    final List<(String name, int coins, int vipTier, bool isMe)> combined = <(String, int, int, bool)>[
      for (final (String name, int coins, int vipTier) p in _mockTopWinners) (p.$1, p.$2, p.$3, false),
      ('You', myBalance, 0, true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return <TopWinEntry>[
      for (int i = 0; i < combined.length; i++)
        TopWinEntry(
          rank: i + 1,
          name: combined[i].$1,
          coins: combined[i].$2,
          vipTier: combined[i].$3,
          isCurrentUser: combined[i].$4,
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    for (int col = 0; col < GameConstants.reelCount; col++) {
      _slotController.reelControllers[col].setIdle(<SlotSymbol>[
        for (int row = 0; row < GameConstants.symbolsPerReel; row++) ReelFrame.sampleGrid[row][col],
      ]);
    }
  }

  @override
  void dispose() {
    _slotController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _onSpin() async {
    if (_slotController.isSpinning) return;
    final GameNotifier notifier = ref.read(gameProvider.notifier);
    final WalletTransactionsNotifier wallet = ref.read(walletTransactionsProvider.notifier);
    final AudioService audio = getIt<AudioService>();
    final GameState stateBeforeSpin = ref.read(gameProvider);
    final int betAtSpinStart = stateBeforeSpin.bet;
    final bool wasFreeSpin = stateBeforeSpin.freeSpinsRemaining > 0;

    setState(() {
      _winningCells = <(int, int)>{};
      _hasWin = false;
      _showNearMiss = false;
      _showJackpot = false;
      _floatingWinAmount = null;
    });

    final outcome = notifier.startSpin();
    if (outcome == null) {
      // Zero balance has no room to top itself back up (daily bonus/
      // missions are off, see AppConstants) — point straight at how to
      // actually get more, rather than the general "top up" nudge that
      // still applies when the player can afford a smaller bet.
      if (stateBeforeSpin.balance <= 0) {
        unawaited(showBuyCreditsSheet(context));
      } else {
        unawaited(showLowBalanceSheet(context));
      }
      return;
    }
    if (!wasFreeSpin) {
      wallet.record(type: TransactionType.loss, label: 'Spin Bet', amount: -betAtSpinStart);
    }

    unawaited(audio.playSfx(SfxType.spin));
    await _slotController.spinTo(outcome.grid);
    if (!mounted) return;

    notifier.resolveSpin();
    setState(() {
      _winningCells = outcome.winningCells;
      _hasWin = outcome.isWin;
      _showNearMiss = outcome.isNearMiss;
      _showJackpot = outcome.isJackpot;
    });

    if (outcome.isJackpot) {
      unawaited(audio.playSfx(SfxType.jackpot));
      wallet.record(type: TransactionType.win, label: 'Jackpot Win', amount: outcome.totalPayout);
      _confettiController.play();
      _burstCoins(intensity: 1.6);
      setState(() => _shakeTrigger++);
      setState(() => _floatingWinAmount = outcome.totalPayout);
    } else if (outcome.isWin) {
      final bool isBigWin = outcome.totalPayout >= betAtSpinStart * 10;
      unawaited(audio.playSfx(isBigWin ? SfxType.bigWin : SfxType.win));
      unawaited(audio.playSfx(SfxType.coinCollect));
      wallet.record(type: TransactionType.win, label: 'Spin Win', amount: outcome.totalPayout);
      _burstCoins(intensity: isBigWin ? 1.3 : 1.0);
      setState(() => _floatingWinAmount = outcome.totalPayout);
      if (isBigWin) {
        _confettiController.play();
        setState(() => _shakeTrigger++);
      }
    }
  }

  void _burstCoins({double intensity = 1.0}) {
    final Vector2 size = _coinGame.size;
    if (size.x <= 0 || size.y <= 0) return;
    _coinGame.burst(origin: Vector2(size.x / 2, size.y / 2), intensity: intensity);
  }

  void _startAutoSpin(int count) {
    setState(() {
      _autoSpinActive = true;
      _autoSpinStopAfter = count;
      _autoSpinRemaining = count;
    });
    unawaited(_runAutoSpinLoop());
  }

  void _stopAutoSpin() {
    setState(() => _autoSpinActive = false);
  }

  /// Repeatedly spins until [_autoSpinStopAfter] is reached, the balance
  /// can no longer cover the bet, a jackpot lands (stopped so the player
  /// can savor it rather than blowing past it), or the player taps STOP.
  Future<void> _runAutoSpinLoop() async {
    while (mounted && _autoSpinActive && _autoSpinRemaining > 0) {
      final GameState game = ref.read(gameProvider);
      final bool canAfford = game.bet <= game.balance || game.freeSpinsRemaining > 0;
      if (!canAfford) break;

      await _onSpin();
      if (!mounted || !_autoSpinActive) return;

      setState(() => _autoSpinRemaining--);
      if (_showJackpot || _autoSpinRemaining <= 0) break;

      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || !_autoSpinActive) return;
    }
    if (mounted) setState(() => _autoSpinActive = false);
  }

  void _showBetOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        // `Consumer` so DoubleBetCard's numbers stay live as the bet
        // changes (tapping DOUBLE, or +/- elsewhere) instead of freezing
        // at whatever the bet was when the sheet opened; `StatefulBuilder`
        // for the auto-spin switch/dropdown's own local UI state.
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final GameState game = ref.watch(gameProvider);
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Container(
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
                      Text('Bet Options', style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      DoubleBetCard(
                        currentBet: game.bet,
                        doubledBet: (game.bet * 2).clamp(AppConstants.minBet, AppConstants.maxBet),
                        onDouble: () => ref.read(gameProvider.notifier).adjustBet(game.bet),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AutoSpinCard(
                        enabled: _autoSpinActive,
                        stopAfter: _autoSpinStopAfter,
                        options: AppConstants.autoSpinOptions,
                        onToggle: (bool enabled) {
                          if (enabled) {
                            _startAutoSpin(_autoSpinStopAfter);
                          } else {
                            _stopAutoSpin();
                          }
                          setSheetState(() {});
                        },
                        onStopAfterChanged: (int? value) {
                          if (value == null) return;
                          setState(() => _autoSpinStopAfter = value);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameState game = ref.watch(gameProvider);
    final bool expanded = context.isExpanded;

    return ScreenBackground(
      bottom: false,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: HomeHeader(
                  balance: game.balance,
                  bet: game.bet,
                  jackpot: game.jackpot,
                  vipTier: 3,
                  onBetDecrement: () => ref.read(gameProvider.notifier).adjustBet(-AppConstants.betStep),
                  onBetIncrement: () => ref.read(gameProvider.notifier).adjustBet(AppConstants.betStep),
                  onBack: () => context.pop(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                  child: expanded ? _buildExpandedBody(context, game) : _buildCompactBody(context, game),
                ),
              ),
              _buildSpinBarDock(context, game),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: RepaintBoundary(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 24,
                    maxBlastForce: 30,
                    minBlastForce: 12,
                    gravity: 0.25,
                    colors: const <Color>[
                      AppColors.gold,
                      AppColors.goldLight,
                      AppColors.neonPurple,
                      AppColors.success,
                      AppColors.orange,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelStack() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ReelFrame(
          controller: _slotController,
          winningCells: _winningCells,
          hasWin: _hasWin,
        ).animate(key: ValueKey<int>(_shakeTrigger)).shakeX(
              hz: 6,
              amount: _shakeTrigger > 0 ? 8 : 0,
              duration: 450.ms,
            ),
        Positioned.fill(child: CoinExplosionOverlay(game: _coinGame)),
        if (_floatingWinAmount != null)
          FloatingWinText(key: UniqueKey(), amount: _floatingWinAmount!),
        if (_showJackpot || _showNearMiss)
          Positioned(
            bottom: 4,
            child: _showJackpot ? const JackpotBanner() : const NearMissBanner(),
          ),
      ],
    );
  }

  /// The reel, always sized to fit whatever vertical space its parent's
  /// [Expanded] gives it — this is what guarantees it never needs to
  /// scroll off-screen regardless of device height.
  Widget _buildReelArea({double maxWidth = 420}) {
    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: AspectRatio(aspectRatio: 1, child: _buildReelStack()),
        ),
      ),
    );
  }

  Widget _buildCompactBody(BuildContext context, GameState game) {
    final int dailyCompleted = ref.watch(dailyBonusSpinsCompletedProvider);
    final bool dailyClaimed = ref.watch(dailyBonusProvider).claimed;
    final bool dailyReady = dailyCompleted >= AppConstants.dailyBonusRequiredSpins && !dailyClaimed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuickStatusRow(
          dailyBonusReady: dailyReady,
          dailyBonusProgress: '$dailyCompleted/${AppConstants.dailyBonusRequiredSpins}',
          winStreak: game.winStreak,
          offerRemaining: const Duration(minutes: 2, seconds: 27),
          onDailyBonusTap: () => context.pushNamed(RouteNames.rewards),
          showDailyBonus: AppConstants.dailyBonusEnabled,
        ),
        _buildReelArea(maxWidth: 380),
        const SizedBox(height: AppSpacing.sm),
        CompactStatsBar(lastWin: game.lastWin, bestWinToday: game.bestWinToday, gamesPlayed: game.totalSpins),
      ],
    );
  }

  Widget _buildExpandedBody(BuildContext context, GameState game) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (AppConstants.dailyBonusEnabled) ...<Widget>[
                  DailyBonusCard(
                    spinsCompleted: ref.watch(dailyBonusSpinsCompletedProvider),
                    claimed: ref.watch(dailyBonusProvider).claimed,
                    spinsRequired: AppConstants.dailyBonusRequiredSpins,
                    rewardCoins: AppConstants.dailyBonusReward,
                    onTap: () => context.pushNamed(RouteNames.rewards),
                    onClaim: () => ref.read(dailyBonusProvider.notifier).claim(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                WinStreakCard(streak: game.winStreak, streakBonusCoins: game.winStreak * 20),
                const SizedBox(height: AppSpacing.md),
                StatsRow(lastWin: game.lastWin, bestWinToday: game.bestWinToday, gamesPlayed: game.totalSpins),
                const SizedBox(height: AppSpacing.md),
                DoubleBetCard(
                  currentBet: game.bet,
                  doubledBet: game.bet * 2,
                  onDouble: () => ref.read(gameProvider.notifier).adjustBet(game.bet),
                ),
                const SizedBox(height: AppSpacing.md),
                AutoSpinCard(
                  enabled: false,
                  stopAfter: AppConstants.autoSpinOptions.first,
                  options: AppConstants.autoSpinOptions,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 5,
          child: Column(
            children: <Widget>[
              const PromoTicker(
                winnerName: 'MegaWinner22',
                winnerAmount: 240,
                offerRemaining: Duration(minutes: 2, seconds: 27),
              ),
              _buildReelArea(),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(child: TopWinsPanel(entries: _topWins(game.balance))),
        ),
      ],
    );
  }

  Widget _buildSpinBarDock(BuildContext context, GameState game) {
    final bool spinning = _slotController.isSpinning;
    final bool freeSpinActive = game.freeSpinsRemaining > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (freeSpinActive)
                  Expanded(
                    child: BadgePill(
                      label: '${game.freeSpinsRemaining} FREE SPINS LEFT',
                      color: AppColors.success,
                      icon: Icons.auto_awesome_rounded,
                      filled: true,
                    ),
                  )
                else
                  const Spacer(),
                PressableScale(
                  onTap: _autoSpinActive ? null : _showBetOptions,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: _autoSpinActive ? AppColors.textMuted : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bet Options',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _autoSpinActive ? AppColors.textMuted : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SpinBar(
              totalBet: game.bet,
              spinning: spinning,
              soundOn: _soundOn,
              turboOn: _turboOn,
              autoSpinActive: _autoSpinActive,
              autoSpinRemaining: _autoSpinActive ? _autoSpinRemaining : null,
              // Always tappable (while not mid-spin) rather than gated on
              // affordability — _onSpin already branches on that itself
              // (spin / Low Balance / Out of Credits), and disabling the
              // button here pre-empted all three, leaving an unaffordable
              // tap look like it silently did nothing.
              onSpin: _onSpin,
              onStopAutoSpin: _stopAutoSpin,
              onBetDecrement: (spinning || _autoSpinActive)
                  ? null
                  : () => ref.read(gameProvider.notifier).adjustBet(-AppConstants.betStep),
              onBetIncrement: (spinning || _autoSpinActive)
                  ? null
                  : () => ref.read(gameProvider.notifier).adjustBet(AppConstants.betStep),
              onSoundToggle: () {
                setState(() => _soundOn = !_soundOn);
                getIt<AudioService>().setSfxEnabled(_soundOn);
              },
              onTurboToggle: (bool value) => setState(() => _turboOn = value),
            ),
          ],
        ),
      ),
    );
  }
}
