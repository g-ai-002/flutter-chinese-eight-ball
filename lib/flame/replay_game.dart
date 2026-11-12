import 'dart:ui';

import 'package:flame/game.dart';

import '../core/frame_idle.dart';
import '../core/replay_player.dart';
import '../providers/settings_provider.dart';
import 'replay_table_component.dart';

/// 回放页的 Flame 入口：推进回放进度并绘制球台。
///
/// 暂停播放时球台是静止画面，空闲后挂起渲染循环；播放、跳杆与逐杆切换
/// 通过 [ReplayPlayer] 的通知立即唤醒。
class ReplayGame extends FlameGame {
  ReplayGame({required this.player, required this.settings});

  final ReplayPlayer player;
  final SettingsProvider settings;

  final FrameIdle _idle = FrameIdle();
  ReplayTableComponent? _table;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    player.addListener(wake);
    final table = ReplayTableComponent(player: player, settings: settings);
    _table = table;
    _fit(table);
    await add(table);
  }

  @override
  void onRemove() {
    player.removeListener(wake);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final animating = player.isPlaying || (_table?.isAnimating ?? false);
    if (_idle.tick(animating, dt)) pauseEngine();
  }

  /// 回放状态变化后调用：重新计时并恢复被挂起的渲染循环。
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

  void _fit(ReplayTableComponent table) {
    table
      ..size = size.clone()
      ..position = Vector2.zero();
  }
}
