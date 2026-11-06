import 'package:flutter/material.dart';

import '../../core/match_trend.dart';

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
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in trend.points)
                  Expanded(child: _DayBar(point: point)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.point});

  final DailyPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rate = point.potRate.clamp(0.0, 1.0).toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: point.isEmpty ? 0.04 : (rate < 0.06 ? 0.06 : rate),
              widthFactor: 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: point.isEmpty
                      ? colors.outlineVariant.withValues(alpha: 0.4)
                      : colors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${point.date.month}/${point.date.day}',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 8,
            color: colors.outline,
          ),
        ),
      ],
    );
  }
}
