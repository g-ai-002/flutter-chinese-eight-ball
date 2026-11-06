import 'package:flutter/material.dart';

import '../../core/match_stats.dart';
import '../../utils/formatters.dart';

/// 统计总览：场次、胜率、杆数与进球表现的指标网格。
class StatsSummaryGrid extends StatelessWidget {
  const StatsSummaryGrid({super.key, required this.stats});

  final MatchStats stats;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: '总场次', value: '${stats.matches}'),
      (
        label: '人机胜率',
        value: stats.aiMatches == 0 ? '—' : formatPercent(stats.aiWinRate),
      ),
      (label: '双人场次', value: '${stats.twoPlayerMatches}'),
      (label: '场均杆数', value: stats.averageShots.toStringAsFixed(1)),
      (label: '累计进球', value: '${stats.potted}'),
      (label: '进球率', value: formatPercent(stats.potRate)),
      (label: '单杆最多', value: '${stats.bestShotPotted} 球'),
      (label: '连续进球', value: '${stats.bestStreak} 杆'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _StatTile(label: item.label, value: item.value),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
