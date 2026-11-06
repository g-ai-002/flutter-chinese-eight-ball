import 'package:flutter/material.dart';

import '../../core/match_trend.dart';
import 'stats_bars.dart';

/// 近 7 天活动：柱高为单日进球率，柱底标注日期，无对局的日期显示细灰柱。
class StatsDaily extends StatelessWidget {
  const StatsDaily({super.key, required this.trend});

  final DailyTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '近 ${trend.points.length} 天 · ${trend.matches} 场 · 柱高为单日进球率',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          StatsBars(
            height: 76,
            minFactor: 0.04,
            bars: [
              for (final point in trend.points)
                StatsBar(
                  heightFactor: point.potRate,
                  muted: point.isEmpty,
                  bottomLabel: '${point.date.month}/${point.date.day}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
