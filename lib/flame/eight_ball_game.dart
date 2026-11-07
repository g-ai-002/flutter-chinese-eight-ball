import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/logic_clock.dart';
import '../core/match_controller.dart';
import '../core/vec.dart';
import '../providers/settings_provider.dart';
import 'table_component.dart';

/// Flame 游戏入口：按所选逻辑速率推进物理时间并绘制球台。
class EightBallGame extends FlameGame {
  EightBallGame({required this.controller, required this.settings, this.placementPreview});

  final MatchController controller;
  final SettingsProvider settings;
  final ValueNotifier<Vec2?>? placementPreview;

  final LogicClock _clock = LogicClock();
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
