import 'dart:math' as math;

import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/physics.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

BallKind kindOf(int id) {
  if (id == 0) return BallKind.cue;
  if (id == 8) return BallKind.eight;
  return id < 8 ? BallKind.solid : BallKind.stripe;
}

BallState ball(int id, double x, double y) =>
    BallState(spec: BallSpec(id, kindOf(id)), position: Vec2(x, y));

void main() {
  test('AI 能打进正对中袋的目标球', () {
    final balls = [ball(0, 1.27, 1.0), ball(1, 1.27, 0.5)];
    final ai = EightBallAi(random: math.Random(7));
    final shot = ai.decide(
      balls: balls,
      group: PlayerGroup.solids,
      onEight: false,
      difficulty: AiDifficulty.hard,
    );

    expect(shot.targetBallId, 1);
    expect(shot.pocketIndex, 1);
    expect(shot.angle, closeTo(-math.pi / 2, 0.05));

    final simulation = ShotSimulation(balls: balls);
    simulation.strike(shot.angle, shot.power);
    final outcome = simulation.simulateToRest(limit: 10);
    expect(outcome.pottedIds, contains(1));
  });

  test('本方还有球时不会把黑八当作目标', () {
    final balls = [ball(0, 0.8, 1.0), ball(3, 1.3, 0.45), ball(8, 1.6, 0.9)];
    final ai = EightBallAi(random: math.Random(3));
    final shot = ai.decide(
      balls: balls,
      group: PlayerGroup.solids,
      onEight: false,
    );
    expect(shot.targetBallId, isNot(8));
    expect(shot.power, inInclusiveRange(0.15, 1.0));
  });

  test('开放球台时不会把黑八当作普通目标', () {
    final balls = [ball(0, 1.27, 1.0), ball(1, 1.27, 0.45), ball(8, 1.9, 0.3)];
    final ai = EightBallAi(random: math.Random(9));
    final shot = ai.decide(balls: balls, group: null, onEight: false);
    expect(shot.targetBallId, isNot(8));
    expect(shot.angle.isFinite, isTrue);
  });

  test('清台后 AI 以黑八为目标', () {
    final balls = [ball(0, 1.27, 1.0), ball(8, 1.27, 0.55)];
    final ai = EightBallAi(random: math.Random(11));
    final shot = ai.decide(
      balls: balls,
      group: PlayerGroup.solids,
      onEight: true,
      difficulty: AiDifficulty.hard,
    );
    expect(shot.targetBallId, 8);
    expect(shot.pocketIndex, isNotNull);
  });

  test('没有可进攻线路时仍会给出合法方向', () {
    final balls = [ball(0, 0.3, 1.0), ball(1, 2.0, 0.3)];
    final ai = EightBallAi(random: math.Random(5));
    final shot = ai.decide(
      balls: balls,
      group: PlayerGroup.solids,
      onEight: false,
      difficulty: AiDifficulty.easy,
    );
    expect(shot.power, greaterThan(0));
    expect(shot.angle.isFinite, isTrue);
  });

  test('难度越低瞄准误差越大', () {
    final balls = [ball(0, 1.27, 1.0), ball(1, 1.27, 0.5)];
    double averageError(AiDifficulty difficulty, int seed) {
      final ai = EightBallAi(random: math.Random(seed));
      final shot = ai.decide(
        balls: balls,
        group: PlayerGroup.solids,
        onEight: false,
        difficulty: difficulty,
      );
      return (shot.angle - -math.pi / 2).abs();
    }

    final easy =
        List.generate(
          6,
          (i) => averageError(AiDifficulty.easy, i + 1),
        ).reduce((a, b) => a + b) /
        6;
    final hard =
        List.generate(
          6,
          (i) => averageError(AiDifficulty.hard, i + 1),
        ).reduce((a, b) => a + b) /
        6;
    expect(easy, greaterThan(hard));
  });
}
