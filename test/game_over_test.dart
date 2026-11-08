import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/flame/eight_ball_game.dart';
import 'package:chinese_eight_ball/pages/game_page.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/match_history_service.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:chinese_eight_ball/theme/app_theme.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 在球台上摆好「清台后黑八正对左上角袋」的球局，玩家二一杆制胜。
Future<MatchController> _pumpOpponentWin(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  StorageService.resetForTests();
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final storage = await StorageService.instance;
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider(storage),
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const GamePage(
          mode: GameMode.twoPlayers,
          difficulty: AiDifficulty.normal,
          humanSide: 0,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 80));

  final controller = tester
      .widget<GameWidget<EightBallGame>>(find.byType(GameWidget<EightBallGame>))
      .game!
      .controller;
  final rules = controller.rules;
  rules
    ..isBreak = false
    ..tableOpen = false
    ..current = 1;
  rules.groups[0] = PlayerGroup.solids;
  rules.groups[1] = PlayerGroup.stripes;
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('对手打进黑八后对局结束：弹窗、锁定击球并保存记录', (tester) async {
    final controller = await _pumpOpponentWin(tester);

    expect(controller.phase, MatchPhase.gameOver);
    expect(controller.rules.winner, 1);
    expect(find.text('玩家二获胜'), findsOneWidget);
    expect(find.text('玩家二获胜 · 对局结束'), findsOneWidget);
    expect(controller.canShoot, isFalse);

    final shoot = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '击 球'));
    expect(shoot.onPressed, isNull, reason: '终局后击球按钮必须禁用');

    final records = await MatchHistoryService.instance.load();
    expect(records, hasLength(1));
    expect(records.single.title, '玩家二获胜');
  });

  testWidgets('终局弹窗不能被系统返回关闭，再来一局恢复新球局', (tester) async {
    final controller = await _pumpOpponentWin(tester);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('玩家二获胜'), findsOneWidget, reason: '系统返回不能留下无法继续的球台');

    await tester.tap(find.text('再来一局'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('玩家二获胜'), findsNothing);
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.rules.over, isFalse);
    expect(controller.balls.where((ball) => ball.active), hasLength(16));
  });
}
