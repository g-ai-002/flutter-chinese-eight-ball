import 'package:flutter/material.dart';

import '../../core/match_controller.dart';

/// 对局状态条：当前回合、上一杆结果与杆数。
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final MatchController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final last = controller.log.isEmpty ? '' : controller.log.last;
    final turn = controller.isAiTurn ? '电脑回合' : '你的回合';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.isAiTurn
                    ? Icons.smart_toy_outlined
                    : Icons.person_outline,
                size: 13,
                color: colors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                controller.phase == MatchPhase.gameOver ? '对局结束' : turn,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        if (!compact)
          Text(
            '第 ${controller.rules.shotNumber} 杆',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
