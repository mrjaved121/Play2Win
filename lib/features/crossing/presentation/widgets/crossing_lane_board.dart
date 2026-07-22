import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import 'hopper_token.dart';
import 'lane_board_painter.dart';
import 'lane_tile.dart';
import 'live_wins_ticker.dart';

/// The play surface: a horizontally-scrolling road of lanes with the
/// player's token hopping across as [currentLane] advances. Auto-scrolls
/// to keep the token roughly centered whenever the lane changes. Purely a
/// renderer of already-known state — it never decides bust/survive itself
/// (see `crossing_providers.dart`'s doc comment on why that has to stay
/// server-side).
class CrossingLaneBoard extends StatefulWidget {
  const CrossingLaneBoard({
    required this.laneCount,
    required this.ladder,
    required this.currentLane,
    required this.busted,
    super.key,
  });

  final int laneCount;

  /// Public payout ladder — ladder[i] = multiplier for lane i+1. May be
  /// shorter than [laneCount] only for one frame while settings are still
  /// loading; missing entries render as a blank badge rather than an error.
  final List<double> ladder;

  /// 0..laneCount — lanes survived so far.
  final int currentLane;

  /// True once the round has resolved as a loss on `currentLane + 1`.
  final bool busted;

  static const double laneWidth = 68;
  static const double boardHeight = 150;
  static const double tokenSize = 40;

  @override
  State<CrossingLaneBoard> createState() => _CrossingLaneBoardState();
}

class _CrossingLaneBoardState extends State<CrossingLaneBoard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(CrossingLaneBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLane != widget.currentLane || oldWidget.laneCount != widget.laneCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final double viewport = _scrollController.position.viewportDimension;
    final double target =
        (widget.currentLane * CrossingLaneBoard.laneWidth) - viewport / 2 + CrossingLaneBoard.laneWidth / 2;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  LaneState _stateFor(int laneIndex) {
    final int laneNumber = laneIndex + 1;
    if (widget.busted && laneNumber == widget.currentLane + 1) return LaneState.busted;
    if (laneNumber <= widget.currentLane) return LaneState.cleared;
    if (laneNumber == widget.currentLane + 1) return LaneState.current;
    return LaneState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final double trackWidth = widget.laneCount * CrossingLaneBoard.laneWidth;
    final double tokenX =
        widget.currentLane * CrossingLaneBoard.laneWidth + (CrossingLaneBoard.laneWidth - CrossingLaneBoard.tokenSize) / 2;

    return ClipRRect(
      borderRadius: AppRadius.radiusMd,
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.card),
        child: Column(
          children: <Widget>[
            const LiveWinsTicker(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: SizedBox(
                  width: trackWidth,
                  height: CrossingLaneBoard.boardHeight,
                  child: Stack(
                    children: <Widget>[
                      CustomPaint(
                        size: Size(trackWidth, CrossingLaneBoard.boardHeight),
                        painter: LaneBoardPainter(laneWidth: CrossingLaneBoard.laneWidth, laneCount: widget.laneCount),
                      ),
                      Row(
                        children: List<Widget>.generate(widget.laneCount, (int i) {
                          final double multiplier = i < widget.ladder.length ? widget.ladder[i] : 1.0;
                          return LaneTile(
                            laneWidth: CrossingLaneBoard.laneWidth,
                            multiplier: multiplier,
                            state: _stateFor(i),
                            showObstacle: i.isOdd,
                          );
                        }),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        left: tokenX,
                        bottom: 14,
                        child: HopperToken(
                          size: CrossingLaneBoard.tokenSize,
                          busted: widget.busted,
                          laneKey: '${widget.currentLane}-${widget.busted}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
