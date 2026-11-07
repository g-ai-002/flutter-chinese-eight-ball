import 'dart:ui';

import '../core/ball.dart';
import '../core/table_geometry.dart';
import '../core/vec.dart';
import 'table_layout.dart';

/// 把屏幕手势坐标换算成台面坐标，并解析命中的球体与袋口。
///
/// 页面层只负责流程控制，命中判定集中在这里，便于单独测试。
class TablePointer {
  TablePointer(this.layout);

  /// 点击球体时的吸附范围（球半径倍数）。
  static const double snapScale = 1.8;

  /// 拖动摆球时抓取球体的范围（球半径倍数）。
  static const double grabScale = 2.4;

  /// 点击袋口时的判定范围（袋口半径倍数）。
  static const double pocketScale = 2.6;

  final TableLayout layout;

  /// 屏幕坐标转台面坐标，并限制在台面内。
  Vec2 toTable(Offset local) => layout
      .toTable(local)
      .clamp(
        TableGeometry.ballRadius,
        TableGeometry.width - TableGeometry.ballRadius,
        TableGeometry.ballRadius,
        TableGeometry.height - TableGeometry.ballRadius,
      );

  /// 点击瞄准时命中的目标球，母球不参与吸附。
  BallState? targetBallAt(Vec2 point, Iterable<BallState> balls) {
    return _nearest(point, balls, range: TableGeometry.ballRadius * snapScale, includeCue: false);
  }

  /// 摆球时抓取的球，包含母球。
  BallState? ballToGrab(Vec2 point, Iterable<BallState> balls) {
    return _nearest(point, balls, range: TableGeometry.ballRadius * grabScale, includeCue: true);
  }

  /// 点击指袋时命中的袋口编号。
  int? pocketAt(Vec2 point) =>
      TableGeometry.pocketAt(point, tolerance: TableGeometry.pocketRadius * pocketScale);

  BallState? _nearest(
    Vec2 point,
    Iterable<BallState> balls, {
    required double range,
    required bool includeCue,
  }) {
    BallState? nearest;
    var distance = range;
    for (final ball in balls) {
      if (!ball.active || (!includeCue && ball.isCue)) continue;
      final current = ball.position.distanceTo(point);
      if (current < distance) {
        distance = current;
        nearest = ball;
      }
    }
    return nearest;
  }
}
