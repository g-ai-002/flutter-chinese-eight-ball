import 'package:flutter/material.dart';

import '../../core/match_record.dart';
import '../../core/replay_player.dart';
import '../../theme/app_theme.dart';

/// 对局结果与来源信息。
class ReplaySummaryBar extends StatelessWidget {
  const ReplaySummaryBar({
    super.key,
    required this.player,
    required this.record,
    this.compact = false,
  });

  final ReplayPlayer player;
  final MatchRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 8 : 10, 14, compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(
            record.playerWin
                ? Icons.emoji_events_outlined
                : Icons.sports_bar_outlined,
            size: 22,
            color: record.playerWin ? appGold : colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${record.subtitle}${compact ? '' : ' · ${record.endReason}'}',
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${player.displayIndex} / ${record.shotCount} 杆',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
