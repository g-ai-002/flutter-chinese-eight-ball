import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/physics.dart';
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

  test('AI 攻打黑八时自动指定袋口', () async {
    final controller = MatchController(
      mode: GameMode.vsAi,
      difficulty: AiDifficulty.easy,
      humanSide: 1,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);
    _prepareOnEight(controller);

    await controller.playAiTurn();
    expect(controller.calledPocket, isNotNull);
    expect(controller.phase, MatchPhase.shooting);
    runToRest(controller);
  });

  test('球在运动中时 AI 不会重复出杆', () async {
    final controller = MatchController(
      mode: GameMode.vsAi,
      difficulty: AiDifficulty.easy,
      humanSide: 1,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    await controller.playAiTurn();
    expect(controller.phase, MatchPhase.shooting);

    await controller.playAiTurn();
    expect(controller.phase, MatchPhase.shooting);

    runToRest(controller);
    expect(controller.rules.shotNumber, 1);
  });

  test('重新开球会清空未消费的击球特效', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller.pendingEffects.add(
      const BallPocketed(
        ballId: 1,
        pocketIndex: 0,
        position: TableGeometry.center,
      ),
    );
    controller.restart();

    expect(controller.pendingEffects, isEmpty);
  });

  test('攻打黑八未指袋时无法出杆，指袋后可击球并在本杆后重置', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);
    _prepareOnEight(controller);

    expect(controller.needsPocketCall, isTrue);
    expect(controller.calledPocket, isNull);

    controller.shoot();
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.rules.shotNumber, 0);

    controller.setCalledPocket(3);
    expect(controller.calledPocket, 3);
    controller.shoot();
    expect(controller.phase, MatchPhase.shooting);

    runToRest(controller);
    expect(controller.calledPocket, isNull);
    expect(controller.rules.shotNumber, 1);
  });

  test('练习模式可拖动任意球摆位', () {
    final controller = MatchController(
      mode: GameMode.practice,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    expect(controller.isPractice, isTrue);
    expect(controller.moveBall(1, TableGeometry.center), isFalse);

    controller.beginBallEdit();
    expect(controller.isEditingBalls, isTrue);
    expect(controller.moveBall(1, TableGeometry.center), isTrue);
    expect(
      controller.balls.firstWhere((ball) => ball.id == 1).position,
      TableGeometry.center,
    );
    expect(controller.moveBall(0, Vec2.zero), isFalse);

    controller.endBallEdit();
    expect(controller.isEditingBalls, isFalse);
  });

  test('练习模式出杆后不换人，并可重打恢复球局', () {
    final controller = MatchController(
      mode: GameMode.practice,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    final before = controller.balls
        .map((ball) => ball.position)
        .toList(growable: false);
    controller
      ..setPower(0.9)
      ..shoot();
    expect(controller.phase, MatchPhase.shooting);

    runToRest(controller);
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.currentPlayer, 0);
    expect(controller.rules.over, isFalse);
    expect(controller.shotCount, 1);
    expect(controller.canUndoPracticeShot, isTrue);

    controller.undoPracticeShot();
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.shotCount, 0);
    expect(controller.canUndoPracticeShot, isFalse);
    for (var i = 0; i < controller.balls.length; i++) {
      expect(controller.balls[i].position, before[i]);
    }
  });

  test('练习模式重置球桌清除杆数', () {
    final controller = MatchController(
      mode: GameMode.practice,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller
      ..setPower(0.5)
      ..shoot();
    runToRest(controller);
    controller.restart();

    expect(controller.shotCount, 0);
    expect(controller.isEditingBalls, isFalse);
    expect(controller.canUndoPracticeShot, isFalse);
    expect(controller.balls.where((ball) => ball.active), hasLength(16));
  });
}

/// 构造「球手 0 已清台、轮到攻打黑八」的控制器状态。
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
  controller.setAimAngle(angleOf(controller.cuePosition, Vec2.zero));
}
