import 'package:flutter/material.dart';

/// 统计页空状态：还没有本机对局时给出引导。
class StatsEmpty extends StatelessWidget {
  const StatsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.query_stats_outlined,
              size: 46,
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text('还没有可统计的对局', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              '完成一局人机或双人对战后，这里会展示胜率、杆数与进球表现。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
