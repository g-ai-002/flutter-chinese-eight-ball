import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/match_controller.dart';
import '../core/vec.dart';
import '../providers/settings_provider.dart';
import 'table_component.dart';

/// Flame 游戏入口：推进物理时间并绘制球台。
class EightBallGame extends FlameGame {
  EightBallGame({required this.controller, required this.settings, this.placementPreview});

  final MatchController controller;
  final SettingsProvider settings;
  final ValueNotifier<Vec2?>? placementPreview;

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
    controller.tick(dt);
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
