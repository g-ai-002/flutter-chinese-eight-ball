import 'package:flutter/material.dart';

import '../../core/replay_player.dart';

/// 播放 / 暂停、上一杆 / 下一杆与进度滑杆。
class ReplayControls extends StatelessWidget {
  const ReplayControls({super.key, required this.player, this.compact = false});

  final ReplayPlayer player;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '上一杆',
              onPressed: player.index <= 0 ? null : player.previous,
              icon: const Icon(Icons.skip_previous, size: 22),
            ),
            Expanded(
              child: Slider(
                value: player.progress.clamp(0.0, 1.0),
                onChanged: player.canPlay
                    ? (value) => player.seek((value * player.total).round())
                    : null,
              ),
            ),
            IconButton(
              tooltip: '下一杆',
              onPressed: player.atEnd ? null : player.next,
              icon: const Icon(Icons.skip_next, size: 22),
            ),
            IconButton.filled(
              tooltip: player.isPlaying ? '暂停' : (player.atEnd ? '重新播放' : '播放'),
              onPressed: player.canPlay ? player.togglePlay : null,
              icon: Icon(
                player.isPlaying
                    ? Icons.pause
                    : (player.atEnd ? Icons.replay : Icons.play_arrow),
                size: 22,
              ),
            ),
          ],
        ),
        if (!compact)
          Text(
            '第 ${player.displayIndex} / ${player.total} 杆 · '
            '${player.isPlaying ? '播放中' : (player.atEnd ? '已结束' : '已暂停')}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
