import 'package:flutter/material.dart';

import '../../core/replay_player.dart';

/// 当前杆的球手与裁定结果。
class ReplayShotOverlay extends StatelessWidget {
  const ReplayShotOverlay({super.key, required this.player});

  final ReplayPlayer player;

  @override
  Widget build(BuildContext context) {
    final shot = player.activeShot;
    if (shot == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final heading = player.atEnd
        ? '终局 · ${player.record.playerName(shot.player)}'
        : '第 ${player.displayIndex} 杆 · ${player.record.playerName(shot.player)}';
    final result = player.atEnd ? player.record.endReason : shot.result;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            result,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
