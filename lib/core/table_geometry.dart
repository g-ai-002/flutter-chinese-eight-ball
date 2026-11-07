import 'dart:math' as math;

import 'ball.dart';
import 'vec.dart';

/// 中式黑八标准台尺寸与袋口布局，长度单位为米。
///
/// 台面 2.54 × 1.27（九尺台），球直径 57.15 mm。袋口按圆心与台面角点重合
/// 建模，球心进入袋口半径即判为落袋。
class TableGeometry {
  TableGeometry._();

  static const double width = 2.54;
  static const double height = 1.27;
  static const double ballRadius = 0.028575;
  static const double pocketRadius = 0.068;

  /// 球与球之间的最小间隙，保证摆球不重叠。
  static const double _contactGap = 0.0004;

  static double get rackSpacing => ballRadius * 2 + _contactGap;

  static const Vec2 footSpot = Vec2(width * 0.75, height / 2);
  static const Vec2 headSpot = Vec2(width * 0.25, height / 2);

  /// 开球线（母球必须放在此线左侧）。
  static const double headStringX = width * 0.25;

  static const Vec2 center = Vec2(width / 2, height / 2);

  static const List<Vec2> pockets = [
    Vec2(0, 0),
    Vec2(width / 2, 0),
    Vec2(width, 0),
    Vec2(0, height),
    Vec2(width / 2, height),
    Vec2(width, height),
  ];

  /// 袋口名称，顺序与 [pockets] 一致，用于指袋提示。
  static const List<String> pocketNames = ['左上角袋', '上中袋', '右上角袋', '左下角袋', '下中袋', '右下角袋'];

  /// 离指定坐标最近的袋口编号。
  static int nearestPocket(Vec2 point) {
    var best = 0;
    var nearest = double.infinity;
    for (var index = 0; index < pockets.length; index++) {
      final distance = point.distanceSquaredTo(pockets[index]);
      if (distance < nearest) {
        nearest = distance;
        best = index;
      }
    }
    return best;
  }

  /// 指定坐标落在哪个袋口的点击范围内；不在任何袋口附近返回 null。
  static int? pocketAt(Vec2 point, {double tolerance = pocketRadius}) {
    final index = nearestPocket(point);
    return point.distanceTo(pockets[index]) <= tolerance ? index : null;
  }

  /// 开球摆球：8 号球在三角形中心，后排两个底角一全一花。
  static List<BallState> rackBalls() {
    const layout = <List<int>>[
      [1],
      [9, 2],
      [10, 8, 3],
      [11, 4, 12, 5],
      [6, 13, 7, 14, 15],
    ];
    final spacing = rackSpacing;
    final rowGap = spacing * math.sqrt(3) / 2;
    final balls = <BallState>[];
    for (var row = 0; row < layout.length; row++) {
      final ids = layout[row];
      final x = footSpot.x + row * rowGap;
      for (var index = 0; index < ids.length; index++) {
        final y = footSpot.y + (index - (ids.length - 1) / 2) * spacing;
        final id = ids[index];
        balls.add(
          BallState(
            spec: BallSpec(
              id,
              id == 8 ? BallKind.eight : (id < 8 ? BallKind.solid : BallKind.stripe),
            ),
            position: Vec2(x, y),
          ),
        );
      }
    }
    balls.add(BallState(spec: kCueBall, position: headSpot));
    return balls;
  }

  /// 开球时母球可放置区域：开球线左侧、避开库边与袋口。
  static bool isValidBreakPlacement(Vec2 position) =>
      isValidCuePlacement(position) && position.x <= headStringX;

  /// 母球自由球摆放合法性：完全在台面内、不与其他球重叠、不压在袋口。
  static bool isValidCuePlacement(Vec2 position, {Iterable<BallState> obstacles = const []}) =>
      isValidBallPlacement(position, obstacles: obstacles);

  /// 任意球（含母球）的摆放合法性，用于练习模式的自由摆球。
  ///
  /// [ignoreId] 指定被移动的球号，避免它挡住自己。
  static bool isValidBallPlacement(
    Vec2 position, {
    Iterable<BallState> obstacles = const [],
    int? ignoreId,
  }) {
    const margin = ballRadius * 0.06;
    if (position.x < ballRadius + margin ||
        position.x > width - ballRadius - margin ||
        position.y < ballRadius + margin ||
        position.y > height - ballRadius - margin) {
      return false;
    }
    for (final pocket in pockets) {
      if (position.distanceTo(pocket) < pocketRadius + ballRadius * 0.35) {
        return false;
      }
    }
    for (final ball in obstacles) {
      if (!ball.active || ball.id == ignoreId) continue;
      if (position.distanceTo(ball.position) < ballRadius * 2 + 0.0005) {
        return false;
      }
    }
    return true;
  }

  /// 在台面上寻找离目标最近的可摆放位置，用于自动摆球。
  static Vec2? nearestValidCueSpot(
    Vec2 desired, {
    Iterable<BallState> obstacles = const [],
    bool breakZone = false,
  }) {
    bool valid(Vec2 point) => breakZone
        ? isValidBreakPlacement(point) && _clearOfBalls(point, obstacles)
        : isValidCuePlacement(point, obstacles: obstacles);

    if (valid(desired)) return desired;
    for (var radius = 0.02; radius <= 0.6; radius += 0.02) {
      for (var step = 0; step < 24; step++) {
        final angle = step * math.pi / 12;
        final candidate = desired + Vec2(math.cos(angle), math.sin(angle)) * radius;
        if (valid(candidate)) return candidate;
      }
    }
    return null;
  }

  static bool _clearOfBalls(Vec2 point, Iterable<BallState> obstacles) {
    for (final ball in obstacles) {
      if (!ball.active || ball.isCue) continue;
      if (point.distanceTo(ball.position) < ballRadius * 2 + 0.0005) {
        return false;
      }
    }
    return true;
  }
}
