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
import 'help_page.dart';
import 'widgets/compact_players.dart';
import 'widgets/game_side_panel.dart';
import 'widgets/power_control.dart';
import 'widgets/status_strip.dart';

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
                            StatusStrip(controller: _controller),
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
                        child: GameSidePanel(
                          controller: _controller,
                          mode: widget.mode,
                          onRestart: _confirmRestart,
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
                    CompactPlayers(controller: _controller),
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
                    StatusStrip(controller: _controller, compact: true),
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
}
