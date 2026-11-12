import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/physics.dart';
import '../core/replay_player.dart';
import '../providers/settings_provider.dart';
import 'shot_audio.dart';
import 'table_scene.dart';

/// 回放球台：绘制球台与落袋动画，并重放出杆、撞击与落袋音效。
class ReplayTableComponent extends PositionComponent {
  ReplayTableComponent({required this.player, required this.settings});

  final ReplayPlayer player;
  final SettingsProvider settings;

  final TableScene _scene = TableScene();
  final ShotAudio _audio = ShotAudio();

  /// 球台上是否还有落袋动画，供回放入口判断能否挂起渲染循环。
  bool get isAnimating => _scene.isAnimating;

  @override
  void update(double dt) {
    super.update(dt);
    player.tick(dt);
    if (player.takeStrike()) _audio.strike();
    _drainEffects(dt);
    _scene.update(dt);
  }

  void _drainEffects(double dt) {
    _audio.drain(player.pendingEffects, dt);
    for (final event in player.pendingEffects) {
      if (event is! BallPocketed) continue;
      _scene.addPot(event, player.balls);
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
