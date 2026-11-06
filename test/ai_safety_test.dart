import 'package:chinese_eight_ball/core/ai_safety.dart';
import 'package:chinese_eight_ball/core/ai_weights.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/physics.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

BallState ball(int id, double x, double y) =>
    BallState(spec: BallSpec.fromId(id), position: Vec2(x, y));

void main() {
  const safety = AiSafety();

  test('没有进球线路时给出轻碰的防守杆', () {
    final balls = [ball(0, 0.5, 0.66), ball(1, 0.03, 0.635), ball(8, 1.9, 0.8)];
    final shot = safety.choose(
      balls: balls,
      targets: [balls[1]],
      group: PlayerGroup.solids,
      onEight: false,
    );

    expect(shot, isNotNull);
    expect(shot!.isSafety, isTrue);
    expect(shot.targetBallId, 1);
    expect(shot.power, lessThanOrEqualTo(0.52));
    expect(shot.score, isPositive);

    final simulation = ShotSimulation(balls: balls);
    simulation.strike(shot.angle, shot.power);
    final outcome = simulation.simulateToRest(limit: 10);
    expect(outcome.firstContact, 1);
    expect(outcome.cuePotted, isFalse);
  });

  test('目标球与母球重合时没有可枚举的防守线路', () {
    final balls = [ball(0, 1.0, 0.635), ball(1, 1.0, 0.635)];
    final shot = safety.choose(
      balls: balls,
      targets: [balls[1]],
      group: PlayerGroup.solids,
      onEight: false,
    );
    expect(shot, isNull);
  });

  test('兜底防守杆轻碰最近的目标球', () {
    final balls = [ball(0, 1.0, 0.635), ball(3, 0.4, 0.5), ball(2, 0.8, 0.6)];
    final shot = safety.fallback(balls: balls, targets: [balls[1], balls[2]]);

    expect(shot.targetBallId, 2);
    expect(shot.power, AiWeights.fallbackPower);
    expect(shot.score, -100);
    expect(shot.isSafety, isTrue);
    expect(
      shot.angle,
      closeTo(angleOf(balls[0].position, balls[2].position), 1e-9),
    );
  });
}
