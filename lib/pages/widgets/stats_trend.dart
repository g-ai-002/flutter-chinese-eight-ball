import 'package:flutter/material.dart';

import '../../core/match_trend.dart';
import '../../utils/formatters.dart';
import 'stats_bars.dart';

/// 近 8 场走势：柱高为单场进球率，圆点标记人机对局胜负。
class StatsTrend extends StatelessWidget {
  const StatsTrend({super.key, required this.trend});

  final MatchTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final points = trend.points;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '近 ${points.length} 场 · 柱高为进球率',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '近期 ${formatPercent(trend.recentPotRate)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatsBars(
            bars: [
              for (final point in points)
                StatsBar(
                  heightFactor: point.potRate,
                  marker: _markerColor(point, colors),
                  topLabel: '${(point.potRate * 100).round()}',
                  bottomLabel:
                      '${point.createdAt.month}/${point.createdAt.day}',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '圆点：人机胜 / 负 · 旧 → 新',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _markerColor(TrendPoint point, ColorScheme colors) {
    final win = point.win;
    if (win == null) return colors.outlineVariant;
    return win ? colors.primary : colors.error;
  }
}
