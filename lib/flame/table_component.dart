import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/match_controller.dart';
import '../core/physics.dart';
import '../core/vec.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import 'painting/aim_painter.dart';
import 'shot_audio.dart';
import 'table_layout.dart';
import 'table_scene.dart';

/// 球台渲染与击球特效：协调台面、球体、瞄准线、球杆与落袋动画。
///
/// 组件本身不处理手势，瞄准与摆球由页面层的 GestureDetector 转发，
/// 这样 Flame 只负责画面与物理推进，交互逻辑更易测试。
class TableComponent extends PositionComponent {
  TableComponent({required this.controller, required this.settings, this.placementPreview});

  final MatchController controller;
  final SettingsProvider settings;

  /// 摆球时手指所在位置，用于绘制半透明母球预览。
  final ValueNotifier<Vec2?>? placementPreview;

  final TableScene _scene = TableScene();
  final AimPainter _aimPainter = AimPainter();
  final ShotAudio _audio = ShotAudio();

  MatchPhase _lastPhase = MatchPhase.aiming;

  /// 球台上是否还有落袋动画，供游戏入口判断能否挂起渲染循环。
  bool get isAnimating => _scene.isAnimating;

  @override
  void update(double dt) {
    super.update(dt);
    _handlePhaseSound();
    _drainEffects(dt);
    _scene.update(dt);
  }

  void _handlePhaseSound() {
    final phase = controller.phase;
    if (phase != _lastPhase) {
      if (phase == MatchPhase.shooting) {
        _audio.strike();
      } else if (phase == MatchPhase.gameOver) {
        final winner = controller.rules.winner;
        final playerWin = controller.mode == GameMode.twoPlayers || winner == controller.humanSide;
        SoundService.play(playerWin ? SoundFeedback.win : SoundFeedback.lose);
      }
      _lastPhase = phase;
    }
  }

  void _drainEffects(double dt) {
    _audio.drain(controller.pendingEffects, dt);
    for (final event in controller.pendingEffects) {
      if (event is! BallPocketed) continue;
      _scene.addPot(event, controller.simulation.balls);
    }
    controller.pendingEffects.clear();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final layout = _scene.layoutFor(Size(size.x, size.y));
    _scene.paintTable(canvas, layout, settings.tableSkin);
    _aimPainter.paintPocketTargets(canvas, layout, controller);
    _scene.paintBalls(canvas, layout, controller.balls);
    _paintAiming(canvas, layout);
    _paintPlacementPreview(canvas, layout);
    _scene.paintPots(canvas, layout);
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
