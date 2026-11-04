import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

void runToRest(MatchController controller, {int maxTicks = 4000}) {
  var ticks = 0;
  while (controller.phase == MatchPhase.shooting && ticks < maxTicks) {
    controller.tick(1 / 60);
    ticks++;
  }
}

void main() {
  test('初始摆球与开球状态', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    expect(controller.balls, hasLength(16));
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.isBreak, isTrue);
    expect(controller.currentPlayer, 0);
    expect(controller.rules.tableOpen, isTrue);
    expect(controller.playerName(0), '玩家一');
  });

  test('出杆后进入运动状态，停稳后记录一杆', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller
      ..setAimAngle(0)
      ..setPower(0.9)
      ..shoot();
    expect(controller.phase, MatchPhase.shooting);

    runToRest(controller);
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.rules.shotNumber, 1);
    expect(controller.log.last, isNotEmpty);
  });

  test('母球落袋后进入自由球摆放，合法摆放恢复击球', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller
      ..setAimAngle(angleOf(controller.cuePosition, Vec2.zero))
      ..setPower(0.95)
      ..shoot();
    runToRest(controller);

    expect(controller.phase, MatchPhase.placingCue);
    expect(controller.rules.ballInHand, isTrue);
    expect(controller.currentPlayer, 1);

    final placed = controller.placeCue(TableGeometry.center);
    expect(placed, isTrue);
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.rules.ballInHand, isFalse);
    expect(controller.cueBall.active, isTrue);
  });

  test('自由球摆到袋口会被拒绝', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller
      ..setAimAngle(angleOf(controller.cuePosition, Vec2.zero))
      ..setPower(0.95)
      ..shoot();
    runToRest(controller);
    expect(controller.phase, MatchPhase.placingCue);

    expect(controller.placeCue(const Vec2(0.01, 0.01)), isFalse);
    expect(controller.phase, MatchPhase.placingCue);
  });

  test('重新开球恢复初始状态', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller
      ..setPower(0.9)
      ..shoot();
    runToRest(controller);
    controller.restart();

    expect(controller.balls.where((ball) => ball.active), hasLength(16));
    expect(controller.rules.shotNumber, 0);
    expect(controller.isBreak, isTrue);
    expect(controller.phase, MatchPhase.aiming);
  });

  test('人机对战轮到 AI 时自动出杆', () async {
    final controller = MatchController(
      mode: GameMode.vsAi,
      difficulty: AiDifficulty.easy,
      humanSide: 1,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    expect(controller.isAiTurn, isTrue);
    expect(controller.isHumanTurn, isFalse);
    expect(controller.rules.shotNumber, 0);

    await controller.playAiTurn();
    expect(controller.phase, MatchPhase.shooting);

    runToRest(controller);
    expect(controller.phase, isNot(MatchPhase.shooting));
    expect(controller.rules.shotNumber, 1);
  });
}
