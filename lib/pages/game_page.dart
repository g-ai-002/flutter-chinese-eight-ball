import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ai.dart';
import '../core/match_controller.dart';
import '../core/table_geometry.dart';
import '../core/vec.dart';
import '../flame/eight_ball_game.dart';
import '../flame/table_layout.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'help_page.dart';
import 'widgets/ball_chip.dart';
import 'widgets/player_bar.dart';
import 'widgets/power_control.dart';

/// 对局页：球台渲染、瞄准手势、力度控制与回合信息。
class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.humanSide,
  });

  final GameMode mode;
  final AiDifficulty difficulty;
  final int humanSide;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final MatchController _controller;
  final ValueNotifier<Vec2?> _placementPreview = ValueNotifier(null);
  SettingsProvider? _settings;
  EightBallGame? _game;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = MatchController(
      mode: widget.mode,
      difficulty: widget.difficulty,
      humanSide: widget.humanSide,
    )..addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    _settings = context.read<SettingsProvider>();
    _game = EightBallGame(
      controller: _controller,
      settings: _settings!,
      placementPreview: _placementPreview,
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _placementPreview.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.phase != MatchPhase.gameOver || _dialogOpen) return;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
  }

  Future<void> _showGameOver() async {
    if (!mounted) return;
    final rules = _controller.rules;
    final winner = rules.winner ?? 0;
    final playerWin =
        widget.mode == GameMode.twoPlayers || winner == widget.humanSide;
    final title = widget.mode == GameMode.twoPlayers
        ? '${_controller.playerName(winner)}获胜'
        : (playerWin ? '你赢了' : '电脑获胜');
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          playerWin ? Icons.emoji_events_outlined : Icons.sports_bar_outlined,
          color: playerWin ? appGold : Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rules.endReason ?? '本局结束',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '共 ${rules.shotNumber} 杆',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('返回首页'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _controller.restart();
              _dialogOpen = false;
            },
            child: const Text('再来一局'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _confirmRestart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重新开球？'),
        content: const Text('当前比分与球局将清空，重新摆球开球。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('重新开球'),
          ),
        ],
      ),
    );
    if (confirmed == true) _controller.restart();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.mode.label),
            Text(
              '中式黑八 · ${widget.difficulty.label}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '玩法规则',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const HelpPage())),
            icon: const Icon(Icons.menu_book_outlined, size: 21),
          ),
          IconButton(
            tooltip: '重新开球',
            onPressed: _confirmRestart,
            icon: const Icon(Icons.restart_alt, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 980 && constraints.maxHeight >= 520;
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _StatusStrip(controller: _controller),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: _buildTable(
                                  game,
                                  constraints.maxWidth - 360,
                                  constraints.maxHeight - 100,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 320,
                        child: _SidePanel(
                          controller: _controller,
                          mode: widget.mode,
                          onRestart: _confirmRestart,
                          remainingIds: _remainingIds,
                          hint: _hintText(),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  children: [
                    _CompactPlayers(controller: _controller),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: _buildTable(
                          game,
                          constraints.maxWidth,
                          constraints.maxHeight - 190,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusStrip(controller: _controller, compact: true),
                    const SizedBox(height: 6),
                    PowerControl(
                      power: _controller.power,
                      onPowerChanged: _controller.setPower,
                      onAimLeft: _canAim
                          ? () => _controller.adjustAim(-0.006)
                          : null,
                      onAimRight: _canAim
                          ? () => _controller.adjustAim(0.006)
                          : null,
                      onShoot: _controller.shoot,
                      canShoot: _canShoot,
                      hint: _hintText(),
                      compact: true,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool get _canAim =>
      _controller.phase == MatchPhase.aiming && _controller.isHumanTurn;

  bool get _canShoot => _canAim;

  Widget _buildTable(EightBallGame game, double maxWidth, double maxHeight) {
    const aspect = TableLayout.aspectRatio;
    var width = math.min(maxWidth, maxHeight * aspect);
    if (width <= 0) width = math.min(maxWidth, 320);
    final height = width / aspect;
    final size = Size(width, height);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _handlePointer(details.localPosition, size, tap: true),
              onPanStart: (details) =>
                  _handlePointer(details.localPosition, size),
              onPanUpdate: (details) =>
                  _handlePointer(details.localPosition, size),
              onPanEnd: (_) => _handlePointerEnd(size),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePointer(Offset local, Size size, {bool tap = false}) {
    final layout = TableLayout(size);
    var point = layout.toTable(local);
    point = point.clamp(
      TableGeometry.ballRadius,
      TableGeometry.width - TableGeometry.ballRadius,
      TableGeometry.ballRadius,
      TableGeometry.height - TableGeometry.ballRadius,
    );

    if (_controller.phase == MatchPhase.placingCue) {
      _placementPreview.value = point;
      if (tap) _tryPlaceCue(point);
      return;
    }
    if (!_canAim) return;

    // 点击球体时自动吸附到球心，便于精确瞄准。
    if (tap) {
      for (final ball in _controller.balls) {
        if (!ball.active || ball.isCue) continue;
        if (ball.position.distanceTo(point) < TableGeometry.ballRadius * 1.8) {
          point = ball.position;
          break;
        }
      }
    }
    _controller.aimAt(point);
  }

  void _handlePointerEnd(Size size) {
    if (_controller.phase != MatchPhase.placingCue) return;
    final preview = _placementPreview.value;
    _placementPreview.value = null;
    if (preview != null) _tryPlaceCue(preview);
  }

  void _tryPlaceCue(Vec2 point) {
    if (_controller.placeCue(point)) return;
    _placementPreview.value = null;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('该位置无法摆放母球，请换一个位置')));
  }

  String _hintText() {
    final controller = _controller;
    return switch (controller.phase) {
      MatchPhase.gameOver => '对局结束',
      MatchPhase.shooting => '球在运动中…',
      MatchPhase.aiThinking => '电脑思考中…',
      MatchPhase.placingCue => '自由球：拖动母球到合法位置',
      MatchPhase.aiming => controller.isHumanTurn ? '拖动球台瞄准，调整力度后击球' : '电脑瞄准中…',
    };
  }

  List<int> _remainingIds(int player) {
    final group = _controller.rules.groupOf(player);
    if (group == null) return const [];
    final ids = [
      for (final ball in _controller.balls)
        if (ball.active && ball.kind == group.kind) ball.id,
    ]..sort();
    if (ids.isEmpty) {
      return [
        for (final ball in _controller.balls)
          if (ball.active && ball.isEight) ball.id,
      ];
    }
    return ids;
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.controller, this.compact = false});

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

class _CompactPlayers extends StatelessWidget {
  const _CompactPlayers({required this.controller});

  final MatchController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final player in [0, 1]) ...[
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
    final label = controller.rules.tableOpen ? '开放球台' : (group?.label ?? '待定');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? colors.primary
              : colors.outline.withValues(alpha: 0.8),
        ),
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
          Text(
            '$label · ${controller.remainingFor(player)} 颗',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.controller,
    required this.mode,
    required this.onRestart,
    required this.remainingIds,
    required this.hint,
  });

  final MatchController controller;
  final GameMode mode;
  final VoidCallback onRestart;
  final List<int> Function(int player) remainingIds;
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
          for (final player in [0, 1]) ...[
            PlayerBar(
              name: controller.playerName(player),
              subtitle: _targetLabel(player),
              remainingBalls: remainingIds(player),
              active: controller.currentPlayer == player && !rules.over,
              isAi: mode == GameMode.vsAi && player != controller.humanSide,
            ),
            const SizedBox(height: 10),
          ],
          Container(
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
                if (rules.ballInHand) ...[
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
          ),
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
            onAimLeft: controller.isHumanTurn
                ? () => controller.adjustAim(-0.006)
                : null,
            onAimRight: controller.isHumanTurn
                ? () => controller.adjustAim(0.006)
                : null,
            onShoot: controller.shoot,
            canShoot:
                controller.phase == MatchPhase.aiming && controller.isHumanTurn,
            hint: hint,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('重新开球'),
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

  String _targetLabel(int player) {
    final rules = controller.rules;
    if (rules.tableOpen) return '开放球台 · 首球定组';
    final group = rules.groupOf(player);
    if (group == null) return '待定';
    final cleared = !controller.balls.any(
      (ball) => ball.active && ball.kind == group.kind,
    );
    return cleared ? '${group.label} · 攻打黑八' : '目标：${group.label}球';
  }
}
