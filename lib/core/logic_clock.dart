import 'dart:math' as math;

/// 逻辑更新速率：物理与对局状态每秒推进的次数。
enum LogicRate {
  hz30(30, '30Hz'),
  hz60(60, '60Hz'),
  hz120(120, '120Hz');

  const LogicRate(this.hz, this.label);

  final int hz;
  final String label;

  double get step => 1 / hz;

  /// 已保存的速率，缺失或未知值回退到 60Hz。
  static LogicRate stored(String? id) =>
      values.firstWhere((rate) => rate.name == id, orElse: () => hz60);
}

/// 固定步长逻辑时钟：把渲染帧的可变 dt 累积成固定步长的逻辑步。
///
/// 低帧率或卡顿时单帧最多推进 [maxStepsPerFrame] 步并丢弃积压，避免追帧
/// 雪崩；静置阶段调用 [reset]，出杆后从完整的一步重新累积。
class LogicClock {
  LogicClock({this.maxStepsPerFrame = 4, this.maxFrameGap = 0.1});

  final int maxStepsPerFrame;
  final double maxFrameGap;

  LogicRate rate = LogicRate.hz60;
  double _accumulator = 0;

  void reset() => _accumulator = 0;

  /// 推进 [dt] 秒，按 [rate] 调用 [onStep]；返回本帧实际推进的步数。
  int advance(double dt, void Function(double step) onStep) {
    if (dt <= 0) return 0;
    _accumulator += math.min(dt, maxFrameGap);
    var steps = 0;
    while (_accumulator >= rate.step && steps < maxStepsPerFrame) {
      onStep(rate.step);
      _accumulator -= rate.step;
      steps++;
    }
    if (steps == maxStepsPerFrame && _accumulator >= rate.step) {
      _accumulator = 0;
    }
    return steps;
  }
}
