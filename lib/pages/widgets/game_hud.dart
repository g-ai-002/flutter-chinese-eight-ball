import 'package:flutter/material.dart';

import '../../core/match_controller.dart';

/// 半透明悬浮底板：顶部信息条、底部操作条、提示条与球局浮层共用同一外观。
class HudSurface extends StatelessWidget {
  const HudSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.radius = 14,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface.withValues(alpha: 0.94),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// 顶部悬浮信息条：返回、玩法、回合、杆数与球局 / 重开操作。
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.inline,
    required this.restartLabel,
    required this.onBack,
    required this.onHelp,
    required this.onRestart,
    required this.onPanel,
  });

  final MatchController controller;
  final String title;
  final String subtitle;
  final String hint;
  final bool inline;
  final String restartLabel;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onRestart;
  final VoidCallback onPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return HudSurface(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        children: [
          _HudIcon(icon: Icons.arrow_back, tooltip: '返回', onTap: onBack),
          const SizedBox(width: 2),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                if (inline)
                  PlayerSummary(controller: controller, dense: true)
                else
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (inline) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    controller.log.isEmpty ? '' : controller.log.last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TurnChip(controller: controller, dense: true),
          ],
          const SizedBox(width: 4),
          _HudIcon(icon: Icons.groups_2_outlined, tooltip: '球局信息', onTap: onPanel),
          _HudIcon(icon: Icons.menu_book_outlined, tooltip: '玩法规则', onTap: onHelp),
          _HudIcon(icon: Icons.restart_alt, tooltip: restartLabel, onTap: onRestart),
        ],
      ),
    );
  }
}

/// 球台下方的悬浮提示条：回合、上一杆、球组与当前提示。
///
/// 三行内容高度固定，文案为空或变长都不会改变高度。
class GameInfoPill extends StatelessWidget {
  const GameInfoPill({super.key, required this.controller, required this.hint});

  final MatchController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final last = controller.log.isEmpty ? '' : controller.log.last;
    return HudSurface(
      radius: 12,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TurnChip(controller: controller),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '第 ${controller.shotCount} 杆',
                style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 3),
          PlayerSummary(controller: controller),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 回合徽标：谁的回合、是否对局结束。
class TurnChip extends StatelessWidget {
  const TurnChip({super.key, required this.controller, this.dense = false});

  final MatchController controller;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = controller.isPractice
        ? Icons.adjust
        : (controller.isAiTurn ? Icons.smart_toy_outlined : Icons.person_outline);
    final label = controller.phase == MatchPhase.gameOver
        ? '对局结束'
        : controller.isPractice
        ? '自由练习'
        : controller.isAiTurn
        ? '电脑回合'
        : '你的回合';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dense) ...[
            const SizedBox(width: 6),
            Text(
              '第 ${controller.shotCount} 杆',
              style: theme.textTheme.labelSmall?.copyWith(color: colors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 双方球组与剩余球数；练习模式展示不限规则的单行说明。
class PlayerSummary extends StatelessWidget {
  const PlayerSummary({super.key, required this.controller, this.dense = false});

  final MatchController controller;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (controller.isPractice) {
      final theme = Theme.of(context);
      return Text(
        '自由练习 · 无规则限制',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _PlayerTag(controller: controller, player: 0, dense: dense),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PlayerTag(controller: controller, player: 1, dense: dense),
        ),
      ],
    );
  }
}

class _PlayerTag extends StatelessWidget {
  const _PlayerTag({required this.controller, required this.player, required this.dense});

  final MatchController controller;
  final int player;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rules = controller.rules;
    final group = rules.groupOf(player);
    final label = rules.tableOpen ? '开放' : (group?.label ?? '待定');
    final active = controller.currentPlayer == player;
    final accent = active ? colors.primary : colors.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          controller.mode == GameMode.vsAi && player != controller.humanSide
              ? Icons.smart_toy_outlined
              : Icons.person_outline,
          size: 13,
          color: accent,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            controller.playerName(player),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: active ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            dense
                ? '$label ${controller.remainingFor(player)}'
                : '$label · ${controller.remainingFor(player)} 颗',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _HudIcon extends StatelessWidget {
  const _HudIcon({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
