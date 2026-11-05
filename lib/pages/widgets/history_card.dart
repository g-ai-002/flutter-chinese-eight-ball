import 'package:flutter/material.dart';

import '../../core/match_record.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// 单场对局卡片：胜负、模式、时间与终局原因，点击进入回放。
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final MatchRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (record.playerWin ? appGold : colors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (record.playerWin ? appGold : colors.primary)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  record.playerWin
                      ? Icons.emoji_events_outlined
                      : Icons.sports_bar_outlined,
                  size: 20,
                  color: record.playerWin ? appGold : colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatDateTime(record.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      record.endReason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 22,
                    color: colors.primary,
                  ),
                  IconButton(
                    tooltip: '删除记录',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
