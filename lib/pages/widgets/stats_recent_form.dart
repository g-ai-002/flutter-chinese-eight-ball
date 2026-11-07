import 'package:flutter/material.dart';

import 'stats_section_hint.dart';

/// 最近战绩：最近 5 场人机对局的胜负徽标与总战绩。
class StatsRecentForm extends StatelessWidget {
  const StatsRecentForm({
    super.key,
    required this.results,
    required this.wins,
    required this.losses,
  });

  /// 按时间从新到旧的胜负结果。
  final List<bool> results;
  final int wins;
  final int losses;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const StatsSectionHint('完成人机对战后显示最近 5 场胜负');
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Row(
        children: [
          for (final win in results) ...[_ResultChip(win: win), const SizedBox(width: 8)],
          const Spacer(),
          Text(
            '$wins 胜 $losses 负',
            style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.win});

  final bool win;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: win ? colors.primary.withValues(alpha: 0.16) : colors.error.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: win ? colors.primary.withValues(alpha: 0.4) : colors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        win ? '胜' : '负',
        style: theme.textTheme.labelSmall?.copyWith(
          color: win ? colors.primary : colors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
