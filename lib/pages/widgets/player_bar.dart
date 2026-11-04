import 'package:flutter/material.dart';

import 'ball_chip.dart';

/// 对局玩家信息条：名称、目标球组、剩余球与当前回合高亮。
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.name,
    required this.subtitle,
    required this.remainingBalls,
    required this.active,
    required this.isAi,
  });

  final String name;
  final String subtitle;
  final List<int> remainingBalls;
  final bool active;
  final bool isAi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = active ? colors.primary : colors.outline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer.withValues(alpha: 0.5)
            : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? colors.primary : colors.outline,
          width: active ? 1.4 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAi ? Icons.smart_toy_outlined : Icons.person_outline,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: active ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '剩 ${remainingBalls.length} 颗',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (remainingBalls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final id in remainingBalls) BallChip(id: id, size: 18),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
