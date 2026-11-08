import '../core/physics.dart';
import '../services/sound_service.dart';

/// 击球音效：把物理事件映射成出杆、撞击与落袋声，实时对局与回放共用。
/// 撞击在一杆内会出现多次，[impactGap] 内的重复撞击只保留一声。
class ShotAudio {
  static const double impactGap = 0.04;

  double _time = 0;
  double _lastImpactAt = -1;

  void strike() => SoundService.play(SoundFeedback.strike);

  /// 推进一帧并消费撞击与落袋事件；落袋动画由调用方另行处理。
  void drain(Iterable<ShotEvent> events, double dt) {
    _time += dt;
    for (final event in events) {
      switch (event) {
        case BallImpact():
          final volume = (event.strength / 3.2).clamp(0.12, 0.85);
          if (_time - _lastImpactAt < impactGap) continue;
          _lastImpactAt = _time;
          SoundService.play(SoundFeedback.impact, volume: volume);
        case BallPocketed():
          SoundService.play(SoundFeedback.pocket, volume: 0.85);
      }
    }
  }
}
