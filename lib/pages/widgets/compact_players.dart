import 'package:flutter/material.dart';

import '../../core/match_controller.dart';

/// 窄屏顶部的双方信息卡片，两列等宽。
class CompactPlayers extends StatelessWidget {
  const CompactPlayers({super.key, required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    final players = controller.isPractice ? [0] : [0, 1];
    return Row(
      children: [
        for (final player in players) ...[
          if (player == 1) const SizedBox(width: 8),
          Expanded(
            child: _CompactPlayerCard(controller: controller, player: player),
          ),
        ],
      ],
    );
  }
}

class _CompactPlayerCard extends StatelessWidget {
  const _CompactPlayerCard({required this.controller, required this.player});

  final MatchController controller;
  final int player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final active = controller.currentPlayer == player;
    final group = controller.rules.groupOf(player);
    final label = controller.isPractice
        ? '自由练习'
        : (controller.rules.tableOpen ? '开放球台' : (group?.label ?? '待定'));
    final detail = controller.isPractice
        ? '第 ${controller.shotCount} 杆'
        : '$label · ${controller.remainingFor(player)} 颗';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? colors.primaryContainer.withValues(alpha: 0.55) : colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? colors.primary : colors.outline.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Icon(
            controller.mode == GameMode.vsAi && player != controller.humanSide
                ? Icons.smart_toy_outlined
                : Icons.person_outline,
            size: 15,
            color: active ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              controller.playerName(player),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(detail, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
