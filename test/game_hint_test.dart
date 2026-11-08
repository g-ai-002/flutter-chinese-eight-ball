import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/pages/game_hint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('练习模式的提示随摆球状态变化', () {
    final controller = MatchController(
      mode: GameMode.practice,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    expect(gameHint(controller), contains('自由练习'));
    controller.beginBallEdit();
    expect(gameHint(controller), contains('摆球模式'));
    controller.endBallEdit();
  });

  test('攻打黑八时提示先指袋，指袋后显示袋口名称', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);
    _prepareOnEight(controller);

    expect(gameHint(controller), contains('先点击袋口'));
    controller.setCalledPocket(4);
    expect(gameHint(controller), contains('下中袋'));
  });

  test('对局阶段提示覆盖摆放母球与运动中', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    expect(gameHint(controller), contains('拖动球台瞄准'));
    controller
      ..setPower(0.9)
      ..shoot();
    expect(gameHint(controller), contains('运动中'));
  });

  test('对局结束后提示内展示获胜方，避免球台看起来还在对局', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);
    _prepareOnEight(controller);

    for (final ball in controller.balls) {
      if (ball.kind == BallKind.solid || ball.kind == BallKind.stripe) ball.active = false;
    }
    final eight = controller.balls.firstWhere((ball) => ball.isEight);
    eight.position = const Vec2(0.15, 0.15);
    controller.cueBall.position = const Vec2(0.5, 0.5);
    controller
      ..setAimAngle(angleOf(controller.cuePosition, eight.position))
      ..setPower(0.5);
    controller.setCalledPocket(0);
    controller.shoot();
    var ticks = 0;
    while (controller.phase == MatchPhase.shooting && ticks < 4000) {
      controller.tick(1 / 60);
      ticks++;
    }

    expect(gameHint(controller), contains('玩家一获胜'));
    expect(gameHint(controller), contains('对局结束'));
  });
}

void _prepareOnEight(MatchController controller) {
  final rules = controller.rules;
  rules
    ..isBreak = false
    ..tableOpen = false
    ..current = 0;
  rules.groups[0] = PlayerGroup.solids;
  rules.groups[1] = PlayerGroup.stripes;
  for (final ball in controller.balls) {
    if (ball.kind == BallKind.solid) ball.active = false;
  }
}
