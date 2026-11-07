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
import 'game_layout.dart';
import 'help_page.dart';
import 'replay_page.dart';
import 'widgets/floating_message.dart';
import 'widgets/game_hud.dart';
import 'widgets/game_over_dialog.dart';
import 'widgets/game_side_panel.dart';
import 'widgets/power_control.dart';
import 'widgets/practice_toolbar.dart';

/// 对局页：球台渲染、瞄准手势、力度控制与回合信息。
///
/// 球台吃满顶部信息条与底部操作条之外的区域，其余信息都叠放在四周的悬浮
/// 条里，文案变化不会影响球台的大小与位置。
class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.mode,
    required this.difficulty,
    this.aiStrength = 0.5,
    required this.humanSide,
  });

  final GameMode mode;
  final AiDifficulty difficulty;
  final double aiStrength;
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
  bool _panelOpen = false;
  int? _dragBallId;
  MatchRecord? _savedRecord;

  @override
  void initState() {
    super.initState();
    _controller = MatchController(
      mode: widget.mode,
      difficulty: widget.difficulty,
      aiStrength: widget.aiStrength,
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
    final playerWin = widget.mode == GameMode.twoPlayers || winner == widget.humanSide;
    final title = _controller.matchTitle;
    final record = _controller.finishedRecord;
    await _saveRecord(record);
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
        onReplay: record == null ? null : () => _openReplay(dialogContext, record),
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

  /// 同一场终局只保存一次，回放后重新打开终局弹窗不会重复写入。
  Future<void> _saveRecord(MatchRecord? record) async {
    if (record == null || _savedRecord?.id == record.id) return;
    await MatchHistoryService.instance.add(record);
    _savedRecord = record;
  }

  Future<void> _openReplay(BuildContext dialogContext, MatchRecord record) async {
    Navigator.of(dialogContext).pop();
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ReplayPage(record: record)));
    // 回放结束后回到终局球台，重新给出「再来一局」入口。
    if (!mounted || _controller.phase != MatchPhase.gameOver) return;
    _dialogOpen = true;
    await _showGameOver();
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

  void _openHelp() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HelpPage()));
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _buildStage(context, game),
          ),
        ),
      ),
    );
  }

  /// 球台居中铺满，四周浮层按固定高度叠放，内容变化不影响球台。
  Widget _buildStage(BuildContext context, EightBallGame game) {
    final theme = Theme.of(context);
    final restartLabel = widget.mode == GameMode.practice ? '重置球桌' : '重新开球';
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = GameLayout(constraints.biggest);
        final hint = gameHint(_controller);
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.95,
                      colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(rect: layout.tableRect, child: _buildTable(game, layout.tableSize)),
            Positioned.fromRect(
              rect: layout.header,
              child: GameHeader(
                controller: _controller,
                title: widget.mode.label,
                subtitle: _subtitle,
                hint: hint,
                inline: layout.inline,
                restartLabel: restartLabel,
                onBack: () => Navigator.of(context).maybePop(),
                onHelp: _openHelp,
                onRestart: _confirmRestart,
                onPanel: () => setState(() => _panelOpen = !_panelOpen),
              ),
            ),
            if (layout.info != null)
              Positioned.fromRect(
                rect: layout.info!,
                child: GameInfoPill(controller: _controller, hint: hint),
              ),
            Positioned.fromRect(
              rect: layout.dock,
              child: HudSurface(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: PowerControl(
                  power: _controller.power,
                  onPowerChanged: _controller.setPower,
                  onAimLeft: _controller.canAim ? () => _controller.adjustAim(-0.006) : null,
                  onAimRight: _controller.canAim ? () => _controller.adjustAim(0.006) : null,
                  onShoot: _controller.shoot,
                  canShoot: _controller.canShoot,
                  singleRow: layout.singleRow,
                ),
              ),
            ),
            if (_panelOpen)
              Positioned.fromRect(
                rect: layout.panel,
                child: GameSidePanel(
                  controller: _controller,
                  mode: widget.mode,
                  hint: hint,
                  onClose: () => setState(() => _panelOpen = false),
                ),
              ),
          ],
        );
      },
    );
  }

  String get _subtitle => switch (widget.mode) {
    GameMode.vsAi => '中式黑八 · ${AiTuning.of(widget.difficulty, widget.aiStrength).label}',
    GameMode.twoPlayers => '中式黑八 · 同屏对局',
    GameMode.practice => '中式黑八 · 自由练习',
  };

  Widget _buildTable(EightBallGame game, Size size) {
    return SizedBox(
      key: const Key('game-table'),
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handlePointer(details.localPosition, size, tap: true),
              onPanStart: (details) => _handlePointer(details.localPosition, size, startDrag: true),
              onPanUpdate: (details) => _handlePointer(details.localPosition, size),
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
                onPreset: _controller.applyPracticePreset,
                selectedPreset: _controller.practicePreset,
              ),
            ),
        ],
      ),
    );
  }

  void _handlePointer(Offset local, Size size, {bool tap = false, bool startDrag = false}) {
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
    showFloatingMessage(context, '该位置无法摆放母球，请换一个位置');
  }
}
