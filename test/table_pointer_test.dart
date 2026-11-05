import 'dart:ui';

import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/flame/table_layout.dart';
import 'package:chinese_eight_ball/flame/table_pointer.dart';
import 'package:flutter_test/flutter_test.dart';

BallState ball(int id, Vec2 position, {bool active = true}) => BallState(
  spec: BallSpec(
    id,
    id == 0 ? BallKind.cue : (id == 8 ? BallKind.eight : BallKind.solid),
  ),
  position: position,
)..active = active;

void main() {
  final layout = TableLayout(const Size(1270, 730));
  final pointer = TablePointer(layout);

  Offset canvasOf(Vec2 point) => layout.toCanvas(point);
  Vec2 tableOf(Offset point) => pointer.toTable(point);

  test('屏幕坐标可换算回台面坐标，并限制在台面内', () {
    expect(tableOf(canvasOf(TableGeometry.center)).x, closeTo(1.27, 1e-6));
    expect(tableOf(canvasOf(TableGeometry.center)).y, closeTo(0.635, 1e-6));

    final outside = pointer.toTable(const Offset(-500, -500));
    expect(outside.x, TableGeometry.ballRadius);
    expect(outside.y, TableGeometry.ballRadius);
  });

  test('点击袋口识别六个袋位，台面中央不误判', () {
    for (var index = 0; index < TableGeometry.pockets.length; index++) {
      expect(
        pointer.pocketAt(tableOf(canvasOf(TableGeometry.pockets[index]))),
        index,
      );
    }
    expect(pointer.pocketAt(TableGeometry.center), isNull);
  });

  test('瞄准吸附只命中目标球，摆球抓取包含母球', () {
    final balls = [
      ball(0, const Vec2(0.4, 0.4)),
      ball(1, const Vec2(0.8, 0.4)),
      ball(2, const Vec2(1.0, 0.7), active: false),
    ];

    expect(pointer.targetBallAt(const Vec2(0.4, 0.4), balls), isNull);
    expect(pointer.targetBallAt(const Vec2(0.805, 0.4), balls)?.id, 1);
    expect(pointer.targetBallAt(const Vec2(1.0, 0.7), balls), isNull);
    expect(pointer.ballToGrab(const Vec2(0.4, 0.4), balls)?.id, 0);
    expect(pointer.ballToGrab(const Vec2(0.9, 0.9), balls), isNull);
  });
}
