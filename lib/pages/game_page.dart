import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ai.dart';
import '../core/match_controller.dart';
import '../core/match_record.dart';
import '../core/vec.dart';
import '../flame/eight_ball_game.dart';
import '../flame/table_layout.dart';
import '../flame/table_pointer.dart';
import '../providers/settings_provider.dart';
import '../services/match_history_service.dart';
import 'game_hint.dart';
import 'help_page.dart';
import 'replay_page.dart';
import 'widgets/compact_players.dart';
import 'widgets/game_over_dialog.dart';
import 'widgets/game_side_panel.dart';
import 'widgets/power_control.dart';
import 'widgets/practice_toolbar.dart';
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
  int? _dragBallId;
  MatchRecord? _savedRecord;

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
    final title = _controller.matchTitle;
    final record = _controller.finishedRecord;
    if (record != null && _savedRecord?.id != record.id) {
      await MatchHistoryService.instance.add(record);
      _savedRecord = record;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameOverDialog(
        title: title,
        playerWin: playerWin,
        reason: rules.endReason ?? '本局结束',
        shots: _controller.shotCount,
        onHome: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
        onReplay: record == null
            ? null
            : () async {
                Navigator.of(dialogContext).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReplayPage(record: record),
                  ),
                );
                // 回放结束后回到终局球台，重新给出「再来一局」入口。
                if (!mounted || _controller.phase != MatchPhase.gameOver) return;
                _dialogOpen = true;
                await _showGameOver();
              },
        onRestart: () {
          Navigator.of(dialogContext).pop();
          _controller.restart();
          _savedRecord = null;
          _dialogOpen = false;
        },
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _confirmRestart() async {
    final practice = widget.mode == GameMode.practice;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(practice ? '重置球桌？' : '重新开球？'),
        content: Text(practice ? '所有球回到初始摆球位置，练习杆数清零。' : '当前比分与球局将清空，重新摆球开球。'),
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
              _subtitle,
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
            tooltip: widget.mode == GameMode.practice ? '重置球桌' : '重新开球',
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
                          hint: gameHint(_controller),
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
                      onAimLeft: _controller.canAim
                          ? () => _controller.adjustAim(-0.006)
                          : null,
                      onAimRight: _controller.canAim
                          ? () => _controller.adjustAim(0.006)
                          : null,
                      onShoot: _controller.shoot,
                      canShoot: _controller.canShoot,
                      hint: gameHint(_controller),
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

  String get _subtitle => switch (widget.mode) {
    GameMode.vsAi => '中式黑八 · ${widget.difficulty.label}',
    GameMode.twoPlayers => '中式黑八 · 同屏对局',
    GameMode.practice => '中式黑八 · 自由练习',
  };

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
                  _handlePointer(details.localPosition, size, startDrag: true),
              onPanUpdate: (details) =>
                  _handlePointer(details.localPosition, size),
              onPanEnd: (_) => _handlePointerEnd(size),
              child: const SizedBox.expand(),
            ),
          ),
          if (widget.mode == GameMode.practice)
            Positioned(
              left: 6,
              top: 6,
              child: PracticeToolbar(
                editing: _controller.isEditingBalls,
                canUndo: _controller.canUndoPracticeShot,
                onToggleEdit: () => _controller.isEditingBalls
                    ? _controller.endBallEdit()
                    : _controller.beginBallEdit(),
                onUndo: _controller.undoPracticeShot,
              ),
            ),
        ],
      ),
    );
  }

  void _handlePointer(
    Offset local,
    Size size, {
    bool tap = false,
    bool startDrag = false,
  }) {
    final pointer = TablePointer(TableLayout(size));
    var point = pointer.toTable(local);

    if (_controller.isEditingBalls) {
      if (tap) return;
      if (startDrag) {
        _dragBallId = pointer.ballToGrab(point, _controller.balls)?.id;
      }
      final id = _dragBallId;
      if (id != null) _controller.moveBall(id, point);
      return;
    }

    if (_controller.phase == MatchPhase.placingCue) {
      _placementPreview.value = point;
      if (tap) _tryPlaceCue(point);
      return;
    }
    if (!_controller.canAim) return;

    // 攻打黑八时点击袋口完成指袋，再正常瞄准。
    if (tap && _controller.needsPocketCall) {
      final pocket = pointer.pocketAt(point);
      if (pocket != null) {
        _controller.setCalledPocket(pocket);
        return;
      }
    }

    // 点击球体时自动吸附到球心，便于精确瞄准。
    if (tap) {
      final target = pointer.targetBallAt(point, _controller.balls);
      if (target != null) point = target.position;
    }
    _controller.aimAt(point);
  }

  void _handlePointerEnd(Size size) {
    _dragBallId = null;
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
}
