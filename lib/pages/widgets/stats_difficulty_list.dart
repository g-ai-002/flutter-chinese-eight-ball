import 'package:flutter/material.dart';

import '../../core/match_stats.dart';
import '../../utils/formatters.dart';
import 'stats_section_hint.dart';

/// 人机难度战绩：每个难度的胜负场次与胜率条。
class StatsDifficultyList extends StatelessWidget {
  const StatsDifficultyList({super.key, required this.difficulties});

  final List<DifficultyStats> difficulties;

  @override
  Widget build(BuildContext context) {
    if (difficulties.isEmpty) {
      return const StatsSectionHint('还没有人机对局');
    }
    return Column(
      children: [for (final difficulty in difficulties) _DifficultyRow(difficulty: difficulty)],
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.difficulty});

  final DifficultyStats difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rate = difficulty.winRate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(difficulty.label, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${difficulty.wins} / ${difficulty.matches} 胜 · '
                '${formatPercent(rate)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 5,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
