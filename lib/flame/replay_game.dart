import 'dart:ui';

import 'package:flame/game.dart';

import '../core/replay_player.dart';
import '../providers/settings_provider.dart';
import 'replay_table_component.dart';

/// 回放页的 Flame 入口：推进回放进度并绘制球台。
class ReplayGame extends FlameGame {
  ReplayGame({required this.player, required this.settings});

  final ReplayPlayer player;
  final SettingsProvider settings;

  ReplayTableComponent? _table;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    final table = ReplayTableComponent(player: player, settings: settings);
    _table = table;
    _fit(table);
    await add(table);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final table = _table;
    if (table != null) _fit(table);
  }

  void _fit(ReplayTableComponent table) {
    table
      ..size = size.clone()
      ..position = Vector2.zero();
  }
}
