import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/frame_idle.dart';
import '../core/logic_clock.dart';
import '../core/match_controller.dart';
import '../core/vec.dart';
import '../providers/settings_provider.dart';
import 'table_component.dart';

/// Flame 游戏入口：按所选逻辑速率推进物理时间并绘制球台。
///
/// 球台停稳后画面不再变化，[FrameIdle] 会计时挂起引擎，避免按屏幕刷新率
/// 空转重绘；交互、回合变化与落袋动画都会重新唤醒渲染循环。
class EightBallGame extends FlameGame {
  EightBallGame({required this.controller, required this.settings, this.placementPreview});

  final MatchController controller;
  final SettingsProvider settings;
  final ValueNotifier<Vec2?>? placementPreview;

  final LogicClock _clock = LogicClock();
  final FrameIdle _idle = FrameIdle();
  TableComponent? _table;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final table = TableComponent(
      controller: controller,
      settings: settings,
      placementPreview: placementPreview,
    );
    _table = table;
    _fit(table);
    await add(table);
  }

  @override
  void update(double dt) {
    if (controller.phase == MatchPhase.shooting) {
      _clock.rate = settings.logicRate;
      _clock.advance(dt, controller.tick);
    } else {
      _clock.reset();
    }
    super.update(dt);
    final animating = controller.phase == MatchPhase.shooting || (_table?.isAnimating ?? false);
    if (_idle.tick(animating, dt)) pauseEngine();
  }

  /// 交互或回合变化后调用：重新计时并恢复被挂起的渲染循环。
  void wake() {
    _idle.markActive();
    if (paused) resumeEngine();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final table = _table;
    if (table != null) _fit(table);
  }

  void _fit(TableComponent table) {
    table
      ..size = size.clone()
      ..position = Vector2.zero();
  }
}
