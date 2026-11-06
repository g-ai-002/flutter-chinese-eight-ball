import 'ball.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// 练习球型模板：开球、直线、贴库、角度、长台与堆球，覆盖常用练习场景。
enum PracticePreset {
  rack('标准开球', []),
  straight('直线球', [
    (0, 0.7, 0.635),
    (1, 1.45, 0.635),
    (9, 1.6, 0.9),
    (8, 1.9, 0.4),
  ]),
  rail('贴库球', [
    (0, 0.8, 0.35),
    (1, 1.65, 0.06),
    (9, 1.9, 1.18),
    (8, 2.15, 0.635),
  ]),
  cut('角度球', [
    (0, 0.75, 0.75),
    (1, 1.55, 0.55),
    (9, 1.9, 0.95),
    (8, 2.2, 0.35),
  ]),
  long('长台直线', [(0, 0.4, 0.9), (1, 2.0, 0.225), (8, 1.3, 0.95)]),
  cluster('堆球', [
    (0, 0.5, 0.635),
    (1, 1.5, 0.635),
    (9, 1.558, 0.664),
    (2, 1.558, 0.606),
    (10, 1.616, 0.635),
    (8, 2.15, 0.9),
  ]);

  const PracticePreset(this.label, this._spots);

  final String label;

  /// 摆位数据：(球号, x, y)，坐标单位为米；开球沿用标准球堆。
  final List<(int, double, double)> _spots;

  List<BallState> layout() => this == rack
      ? TableGeometry.rackBalls()
      : [
          for (final (id, x, y) in _spots)
            BallState(spec: BallSpec.fromId(id), position: Vec2(x, y)),
        ];
}
