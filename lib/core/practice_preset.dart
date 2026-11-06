import 'ball.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// 练习球型模板：开球、直线、贴库、角度、长台与堆球，覆盖常用练习场景。
enum PracticePreset {
  rack('标准开球'),
  straight('直线球'),
  rail('贴库球'),
  cut('角度球'),
  long('长台直线'),
  cluster('堆球');

  const PracticePreset(this.label);

  final String label;

  List<BallState> layout() => switch (this) {
    rack => TableGeometry.rackBalls(),
    straight => [
      _ball(0, 0.7, 0.635),
      _ball(1, 1.45, 0.635),
      _ball(9, 1.6, 0.9),
      _ball(8, 1.9, 0.4),
    ],
    rail => [
      _ball(0, 0.8, 0.35),
      _ball(1, 1.65, 0.06),
      _ball(9, 1.9, 1.18),
      _ball(8, 2.15, 0.635),
    ],
    cut => [
      _ball(0, 0.75, 0.75),
      _ball(1, 1.55, 0.55),
      _ball(9, 1.9, 0.95),
      _ball(8, 2.2, 0.35),
    ],
    long => [_ball(0, 0.4, 0.9), _ball(1, 2.0, 0.225), _ball(8, 1.3, 0.95)],
    cluster => [
      _ball(0, 0.5, 0.635),
      _ball(1, 1.5, 0.635),
      _ball(9, 1.558, 0.664),
      _ball(2, 1.558, 0.606),
      _ball(10, 1.616, 0.635),
      _ball(8, 2.15, 0.9),
    ],
  };

  static BallState _ball(int id, double x, double y) =>
      BallState(spec: BallSpec.fromId(id), position: Vec2(x, y));
}
