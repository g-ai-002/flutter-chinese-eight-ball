import 'package:flutter/material.dart';

import '../../core/match_stats.dart';
import '../../utils/formatters.dart';

/// 近 8 场走势：柱高为单场进球率，圆点标记人机对局胜负。
class StatsTrend extends StatelessWidget {
  const StatsTrend({super.key, required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final recent = points.length <= 3
        ? points
        : points.sublist(points.length - 3);
    final shots = recent.fold(0, (sum, point) => sum + point.shots);
    final potted = recent.fold(0, (sum, point) => sum + point.potted);
    final rate = shots == 0 ? 0.0 : potted / shots;

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
                '近期 ${formatPercent(rate)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Expanded(child: _TrendBar(point: point)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: colors.primary, label: '人机胜'),
              const SizedBox(width: 10),
              _LegendDot(color: colors.error, label: '人机负'),
              const Spacer(),
              Text(
                '旧 → 新',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.point});

  final TrendPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final win = point.win;
    final marker = win == null
        ? colors.outlineVariant
        : (win ? colors.primary : colors.error);
    final rate = point.potRate.clamp(0.0, 1.0).toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: marker, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: rate < 0.06 ? 0.06 : rate,
              widthFactor: 0.52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(point.potRate * 100).round()}',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 8.5,
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          '${point.createdAt.month}/${point.createdAt.day}',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 8,
            color: colors.outline,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
