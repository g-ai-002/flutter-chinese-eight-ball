/// 渲染循环空闲判定。
///
/// 球台停稳后画面完全静止，Flame 仍按屏幕刷新率逐帧重绘，持续消耗 GPU 与
/// 电量。累计空闲 [timeout] 秒后建议挂起引擎，交互或回合变化时再恢复。
class FrameIdle {
  FrameIdle({this.timeout = 0.4});

  /// 触发挂起所需的连续空闲时长（秒）。
  final double timeout;

  double _idle = 0;

  /// 一次有效交互或画面变化：重新开始计时。
  void markActive() => _idle = 0;

  /// 推进一帧；[active] 表示画面仍有动态内容（球运动、落袋动画等）。
  bool tick(bool active, double dt) {
    if (active) {
      _idle = 0;
      return false;
    }
    _idle += dt > 0 ? dt : 1 / 60;
    return _idle >= timeout;
  }
}
