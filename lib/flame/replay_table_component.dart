import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/physics.dart';
import '../core/replay_player.dart';
import '../providers/settings_provider.dart';
import 'table_scene.dart';

/// 回放球台：只负责绘制与落袋动画，播放进度由 [ReplayPlayer] 驱动。
class ReplayTableComponent extends PositionComponent {
  ReplayTableComponent({required this.player, required this.settings});

  final ReplayPlayer player;
  final SettingsProvider settings;

  final TableScene _scene = TableScene();

  @override
  void update(double dt) {
    super.update(dt);
    player.tick(dt);
    _drainEffects();
    _scene.update(dt);
  }

  void _drainEffects() {
    if (player.pendingEffects.isEmpty) return;
    for (final event in player.pendingEffects) {
      if (event is! BallPocketed) continue;
      _scene.addPot(
        event,
        player.balls.firstWhere((item) => item.id == event.ballId),
      );
    }
    player.pendingEffects.clear();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final layout = _scene.layoutFor(Size(size.x, size.y));
    _scene.paintTable(canvas, layout, settings.tableSkin);
    _scene.paintBalls(canvas, layout, player.balls);
    _scene.paintPots(canvas, layout);
  }
}
