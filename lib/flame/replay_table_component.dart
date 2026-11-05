import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/physics.dart';
import '../core/replay_player.dart';
import '../providers/settings_provider.dart';
import 'painting/ball_painter.dart';
import 'painting/pot_painter.dart';
import 'painting/table_painter.dart';
import 'table_layout.dart';

/// 回放球台：只负责绘制与落袋动画，播放进度由 [ReplayPlayer] 驱动。
class ReplayTableComponent extends PositionComponent {
  ReplayTableComponent({required this.player, required this.settings});

  final ReplayPlayer player;
  final SettingsProvider settings;

  final TablePainter _tablePainter = TablePainter();
  final BallPainter _ballPainter = BallPainter();
  final PotPainter _potPainter = PotPainter();
  final List<PotAnimation> _potAnimations = [];

  TableLayout? _layout;
  Size _layoutSize = Size.zero;

  @override
  void update(double dt) {
    super.update(dt);
    player.tick(dt);
    _drainEffects();
    for (final animation in _potAnimations) {
      animation.progress += dt / 0.36;
    }
    _potAnimations.removeWhere((animation) => animation.progress >= 1);
  }

  void _drainEffects() {
    if (player.pendingEffects.isEmpty) return;
    for (final event in player.pendingEffects) {
      if (event is! BallPocketed) continue;
      final ball = player.balls.firstWhere((item) => item.id == event.ballId);
      _potAnimations.add(
        PotAnimation(
          from: event.position,
          pocketIndex: event.pocketIndex,
          ballId: event.ballId,
          kind: ball.kind,
        ),
      );
    }
    player.pendingEffects.clear();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final layout = _layoutFor(Size(size.x, size.y));
    _tablePainter.paint(canvas, layout, settings.tableSkin);
    _ballPainter.paintShadows(canvas, layout, player.balls);
    for (final ball in player.balls) {
      if (!ball.active) continue;
      _ballPainter.paintBall(canvas, layout, ball);
    }
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
}
