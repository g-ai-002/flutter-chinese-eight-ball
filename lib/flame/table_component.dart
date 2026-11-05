import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/match_controller.dart';
import '../core/physics.dart';
import '../core/vec.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import 'painting/aim_painter.dart';
import 'painting/ball_painter.dart';
import 'painting/pot_painter.dart';
import 'painting/table_painter.dart';
import 'table_layout.dart';

/// 球台渲染与击球特效：协调台面、球体、瞄准线、球杆与落袋动画。
///
/// 组件本身不处理手势，瞄准与摆球由页面层的 GestureDetector 转发，
/// 这样 Flame 只负责画面与物理推进，交互逻辑更易测试。
class TableComponent extends PositionComponent {
  TableComponent({
    required this.controller,
    required this.settings,
    this.placementPreview,
  });

  final MatchController controller;
  final SettingsProvider settings;

  /// 摆球时手指所在位置，用于绘制半透明母球预览。
  final ValueNotifier<Vec2?>? placementPreview;

  final TablePainter _tablePainter = TablePainter();
  final BallPainter _ballPainter = BallPainter();
  final AimPainter _aimPainter = AimPainter();
  final PotPainter _potPainter = PotPainter();
  final List<PotAnimation> _potAnimations = [];

  TableLayout? _layout;
  Size _layoutSize = Size.zero;
  MatchPhase _lastPhase = MatchPhase.aiming;
  double _lastImpactAt = -1;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _handlePhaseSound();
    _drainEffects();
    for (final animation in _potAnimations) {
      animation.progress += dt / 0.36;
    }
    _potAnimations.removeWhere((animation) => animation.progress >= 1);
  }

  void _handlePhaseSound() {
    final phase = controller.phase;
    if (phase != _lastPhase) {
      if (phase == MatchPhase.shooting) {
        SoundService.play(SoundFeedback.strike);
      } else if (phase == MatchPhase.gameOver) {
        final winner = controller.rules.winner;
        final playerWin =
            controller.mode == GameMode.twoPlayers ||
            winner == controller.humanSide;
        SoundService.play(playerWin ? SoundFeedback.win : SoundFeedback.lose);
      }
      _lastPhase = phase;
    }
  }

  void _drainEffects() {
    if (controller.pendingEffects.isEmpty) return;
    for (final event in controller.pendingEffects) {
      switch (event) {
        case BallImpact():
          if (_time - _lastImpactAt < 0.04) continue;
          _lastImpactAt = _time;
          final volume = (event.strength / 3.2).clamp(0.12, 0.85);
          SoundService.play(SoundFeedback.impact, volume: volume);
        case BallPocketed():
          SoundService.play(SoundFeedback.pocket, volume: 0.85);
          final ball = controller.simulation.balls.firstWhere(
            (item) => item.id == event.ballId,
          );
          _potAnimations.add(
            PotAnimation(
              from: event.position,
              pocketIndex: event.pocketIndex,
              ballId: event.ballId,
              kind: ball.kind,
            ),
          );
      }
    }
    controller.pendingEffects.clear();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final layout = _layoutFor(Size(size.x, size.y));
    _tablePainter.paint(canvas, layout, settings.tableSkin);
    _ballPainter.paintShadows(canvas, layout, controller.balls);
    for (final ball in controller.balls) {
      if (!ball.active) continue;
      _ballPainter.paintBall(canvas, layout, ball);
    }
    _paintAiming(canvas, layout);
    _paintPlacementPreview(canvas, layout);
    for (final animation in _potAnimations) {
      _potPainter.paint(canvas, layout, animation);
    }
  }

  TableLayout _layoutFor(Size size) {
    final cached = _layout;
    if (cached != null && _layoutSize == size) return cached;
    _layoutSize = size;
    return _layout = TableLayout(size);
  }

  void _paintAiming(Canvas canvas, TableLayout layout) {
    if (controller.phase != MatchPhase.aiming || !controller.cueBall.active) {
      return;
    }
    _aimPainter.paintCue(canvas, layout, controller);
    if (settings.showAimGuide) {
      _aimPainter.paintGuide(canvas, layout, controller);
    }
  }

  void _paintPlacementPreview(Canvas canvas, TableLayout layout) {
    if (controller.phase != MatchPhase.placingCue) return;
    final preview = placementPreview?.value ?? controller.cueBall.position;
    _aimPainter.paintPlacementPreview(canvas, layout, controller, preview);
  }
}
