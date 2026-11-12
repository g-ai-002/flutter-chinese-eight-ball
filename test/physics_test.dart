import 'dart:math' as math;

import 'package:chinese_eight_ball/core/aim.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/physics.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

BallKind kindOf(int id) {
  if (id == 0) return BallKind.cue;
  if (id == 8) return BallKind.eight;
  return id < 8 ? BallKind.solid : BallKind.stripe;
}

BallState ball(
  int id,
  double x,
  double y, {
  double vx = 0,
  double vy = 0,
  bool active = true,
}) => BallState(
  spec: BallSpec(id, kindOf(id)),
  position: Vec2(x, y),
  velocity: Vec2(vx, vy),
)..active = active;

void settle(ShotSimulation simulation, {int maxSteps = 4000}) {
  var steps = 0;
  while (!simulation.settled && steps < maxSteps) {
    simulation.step(1 / 120);
    steps++;
  }
}

void main() {
  group('摩擦与停止', () {
    test('母球出杆后最终停稳并留在台面内', () {
      final simulation = ShotSimulation(balls: [ball(0, 0.6, 0.635)]);
      simulation.strike(0.2, 0.8);
      expect(simulation.cueBall.speed, greaterThan(3));

      settle(simulation);

      final cue = simulation.cueBall;
      expect(cue.speed, 0);
      expect(cue.position.x, inInclusiveRange(0, TableGeometry.width));
      expect(cue.position.y, inInclusiveRange(0, TableGeometry.height));
      expect(simulation.timedOut, isFalse);
    });

    test('空台不会自己产生运动', () {
      final simulation = ShotSimulation(balls: [ball(0, 1.0, 0.6)]);
      expect(simulation.settled, isTrue);
      expect(simulation.step(1 / 60), isFalse);
    });

    test('静止球不随物理步进漂移', () {
      final simulation = ShotSimulation(
        balls: [ball(0, 0.8, 0.635), ball(1, 1.6, 0.3), ball(2, 0.7, 1.0)],
      );
      simulation.strike(math.pi, 0.5);
      final before = [
        for (final item in simulation.balls.skip(1)) item.position,
      ];

      for (var i = 0; i < 60; i++) {
        simulation.step(1 / 120);
      }

      for (var i = 0; i < before.length; i++) {
        final rest = simulation.balls[i + 1];
        expect(rest.position.x, before[i].x);
        expect(rest.position.y, before[i].y);
        expect(rest.velocity, Vec2.zero);
      }
    });
  });

  group('碰撞', () {
    test('母球正面撞击目标球后动量传递', () {
      final simulation = ShotSimulation(
        balls: [ball(0, 0.8, 0.635), ball(1, 1.05, 0.635)],
      );
      simulation.strike(0, 0.5);
      settle(simulation);

      expect(simulation.firstContact, 1);
      final target = simulation.balls.firstWhere((item) => item.id == 1);
      expect(target.position.x, greaterThan(1.05));
    });

    test('斜向撞击会把目标球推向切球方向', () {
      final simulation = ShotSimulation(
        balls: [ball(0, 0.7, 0.635), ball(1, 1.02, 0.66)],
      );
      simulation.strike(0.05, 0.55);
      settle(simulation);

      final target = simulation.balls.firstWhere((item) => item.id == 1);
      expect(target.position.x, greaterThan(1.02));
      expect(target.position.y, greaterThan(0.66));
    });

    test('落袋事件记录球号与袋口', () {
      final simulation = ShotSimulation(
        balls: [ball(3, 0.16, 0.16, vx: -1.4, vy: -1.4)],
      );
      settle(simulation);

      final potted = simulation.events.whereType<BallPocketed>().toList();
      expect(potted, hasLength(1));
      expect(potted.first.ballId, 3);
      expect(potted.first.pocketIndex, 0);
      expect(simulation.balls.first.active, isFalse);
    });
  });

  group('库边', () {
    test('碰库后反弹并损失动能', () {
      final simulation = ShotSimulation(
        balls: [ball(0, TableGeometry.width - 0.3, 0.95, vx: 2.2)],
      );
      var bounced = false;
      for (var i = 0; i < 600 && !simulation.settled; i++) {
        simulation.step(1 / 120);
        final cue = simulation.cueBall;
        if (cue.velocity.x < 0) {
          bounced = true;
          expect(
            cue.position.x,
            lessThanOrEqualTo(
              TableGeometry.width - TableGeometry.ballRadius + 1e-6,
            ),
          );
          expect(cue.velocity.x.abs(), lessThan(2.2));
          break;
        }
      }
      expect(bounced, isTrue);
    });
  });

  group('瞄准辅助', () {
    test('对准目标球时给出幽灵球与去向', () {
      final aim = solveAim(
        cue: const Vec2(0.6, 0.635),
        balls: [ball(1, 1.0, 0.635)],
        angle: 0,
      );
      expect(aim.targetBallId, 1);
      expect(
        aim.ghostCenter!.x,
        closeTo(1.0 - TableGeometry.ballRadius * 2, 1e-6),
      );
      expect(aim.targetDirection!.x, closeTo(1, 1e-6));
    });

    test('没有目标球时指向库边', () {
      final aim = solveAim(
        cue: const Vec2(0.6, 0.635),
        balls: const [],
        angle: 0,
      );
      expect(aim.ghostCenter, isNull);
      expect(
        aim.cushionPoint!.x,
        closeTo(TableGeometry.width - TableGeometry.ballRadius, 1e-6),
      );
    });

    test('反向瞄准不会命中身后的球', () {
      final aim = solveAim(
        cue: const Vec2(0.6, 0.635),
        balls: [ball(1, 0.3, 0.635)],
        angle: math.pi / 2,
      );
      expect(aim.targetBallId, isNull);
    });
  });
}
