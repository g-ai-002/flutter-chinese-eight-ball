import 'package:flutter/material.dart';

import '../../core/match_controller.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../help_page.dart';
import 'ball_chip.dart';
import 'player_bar.dart';
import 'power_control.dart';

/// 宽屏侧栏：双方球组、对局提示、击球记录与力度控制。
class GameSidePanel extends StatelessWidget {
  const GameSidePanel({
    super.key,
    required this.controller,
    required this.mode,
    required this.onRestart,
    required this.hint,
  });

  final MatchController controller;
  final GameMode mode;
  final VoidCallback onRestart;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rules = controller.rules;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final player
              in (controller.isPractice ? const [0] : const [0, 1])) ...[
            PlayerBar(
              name: controller.playerName(player),
              subtitle: _targetLabel(player),
              remainingBalls: _remainingIds(player),
              active: controller.currentPlayer == player && !rules.over,
              isAi: mode == GameMode.vsAi && player != controller.humanSide,
            ),
            const SizedBox(height: 10),
          ],
          _buildStatusCard(context),
          const SizedBox(height: 12),
          Text(
            '击球记录',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in controller.log.reversed.take(
            AppConstants.maxVisibleLog,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '·',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      line,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          PowerControl(
            power: controller.power,
            onPowerChanged: controller.setPower,
            onAimLeft: controller.canAim
                ? () => controller.adjustAim(-0.006)
                : null,
            onAimRight: controller.canAim
                ? () => controller.adjustAim(0.006)
                : null,
            onShoot: controller.shoot,
            canShoot: controller.canShoot,
            hint: hint,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text(controller.isPractice ? '重置球桌' : '重新开球'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HelpPage()),
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('规则'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '瞄准 ${formatAngle(controller.aimAngle)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.phase == MatchPhase.gameOver
                ? '对局结束'
                : controller.isPractice
                ? '自由练习'
                : '${controller.playerName(controller.currentPlayer)}击球',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (controller.rules.ballInHand) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const CueBallChip(size: 16),
                const SizedBox(width: 6),
                Text(
                  '自由球，可任意摆放母球',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _targetLabel(int player) {
    if (controller.isPractice) return '自由练习 · 无规则限制';
    final rules = controller.rules;
    if (rules.tableOpen) return '开放球台 · 首球定组';
    final group = rules.groupOf(player);
    if (group == null) return '待定';
    final cleared = !controller.balls.any(
      (ball) => ball.active && ball.kind == group.kind,
    );
    return cleared ? '${group.label} · 攻打黑八' : '目标：${group.label}球';
  }

  /// 该球手剩余的目标球号；清台后展示待打的黑八。
  List<int> _remainingIds(int player) {
    if (controller.isPractice) {
      return [
        for (final ball in controller.balls)
          if (ball.active && !ball.isCue) ball.id,
      ]..sort();
    }
    final group = controller.rules.groupOf(player);
    if (group == null) return const [];
    final ids = [
      for (final ball in controller.balls)
        if (ball.active && ball.kind == group.kind) ball.id,
    ]..sort();
    if (ids.isNotEmpty) return ids;
    return [
      for (final ball in controller.balls)
        if (ball.active && ball.isEight) ball.id,
    ];
  }
}
