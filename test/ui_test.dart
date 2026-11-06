import 'package:chinese_eight_ball/app.dart';
import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/match_record.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/pages/game_page.dart';
import 'package:chinese_eight_ball/pages/help_page.dart';
import 'package:chinese_eight_ball/pages/history_page.dart';
import 'package:chinese_eight_ball/pages/home_page.dart';
import 'package:chinese_eight_ball/pages/replay_page.dart';
import 'package:chinese_eight_ball/pages/settings_page.dart';
import 'package:chinese_eight_ball/pages/stats_page.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/match_history_service.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MatchRecord sampleReplayRecord() {
  final balls = TableGeometry.rackBalls();
  final cue = balls.firstWhere((ball) => ball.isCue);
  return MatchRecord(
    id: 'replay-1',
    createdAt: DateTime(2026, 11, 5, 20, 30),
    mode: 'twoPlayers',
    modeLabel: '双人对战',
    difficultyLabel: '进阶',
    humanSide: 0,
    winner: 0,
    winnerName: '玩家一',
    title: '玩家一获胜',
    playerWin: true,
    endReason: '清台后打进黑八',
    shots: [
      ReplayShot(
        player: 0,
        balls: balls,
        angle: angleOf(cue.position, TableGeometry.footSpot),
        power: 0.8,
        calledPocket: null,
        result: '开球',
        potted: const [],
      ),
    ],
  );
}

Future<SettingsProvider> pumpPage(WidgetTester tester, Widget page) async {
  final storage = await StorageService.instance;
  final settings = SettingsProvider(storage);
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: MaterialApp(home: page),
    ),
  );
  await tester.pump();
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  testWidgets('应用启动显示首页入口', (tester) async {
    final storage = await StorageService.instance;
    await tester.pumpWidget(EightBallApp(storage: storage));
    await tester.pump();

    expect(find.text('中式黑八'), findsWidgets);
    expect(find.text('人机对战'), findsOneWidget);
    expect(find.text('双人对战'), findsOneWidget);
    expect(find.text('自由练习'), findsOneWidget);
    expect(find.text('最近对局'), findsOneWidget);
    expect(find.text('数据统计'), findsOneWidget);
    expect(find.text('玩法规则'), findsOneWidget);
    expect(find.textContaining('v0.4.0'), findsOneWidget);
  });

  testWidgets('首页进入设置页', (tester) async {
    await pumpPage(tester, const HomePage());
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('AI 难度'), findsOneWidget);
    expect(find.text('球台配色'), findsOneWidget);
    expect(find.text('深色模式'), findsOneWidget);
  });

  testWidgets('设置页三种球台都可见', (tester) async {
    await pumpPage(tester, const SettingsPage());

    expect(find.text('翡翠台呢'), findsOneWidget);
    expect(find.text('午夜蓝'), findsOneWidget);
    expect(find.text('酒红呢'), findsOneWidget);
  });

  testWidgets('玩法规则页列出核心规则', (tester) async {
    await pumpPage(tester, const HelpPage());

    expect(find.text('目标'), findsOneWidget);
    expect(find.text('开球'), findsOneWidget);
    expect(find.text('犯规与自由球'), findsOneWidget);
    expect(find.text('黑八胜负'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.text('对局回放'), findsOneWidget);
  });

  testWidgets('最近对局为空时显示引导文案', (tester) async {
    await pumpPage(tester, const HistoryPage());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('最近对局'), findsOneWidget);
    expect(find.text('还没有对局记录'), findsOneWidget);
  });

  testWidgets('最近对局列出已保存记录并可打开回放', (tester) async {
    await MatchHistoryService.instance.add(sampleReplayRecord());
    await pumpPage(tester, const HistoryPage());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('玩家一获胜'), findsOneWidget);
    expect(find.textContaining('双人对战'), findsOneWidget);
    expect(find.text('清台后打进黑八'), findsOneWidget);

    await tester.tap(find.text('玩家一获胜'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('对局回放'), findsOneWidget);
    expect(find.textContaining('第 1 杆'), findsWidgets);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('回放页播放按钮推进到终局', (tester) async {
    await pumpPage(tester, ReplayPage(record: sampleReplayRecord()));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.pause), findsOneWidget);

    for (var i = 0; i < 420; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byIcon(Icons.replay), findsOneWidget);
    expect(find.text('1 / 1 杆'), findsOneWidget);
  });

  testWidgets('双人对局页渲染球台与击球按钮', (tester) async {
    await pumpPage(
      tester,
      const GamePage(
        mode: GameMode.twoPlayers,
        difficulty: AiDifficulty.normal,
        humanSide: 0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('双人对战'), findsOneWidget);
    expect(find.text('击 球'), findsOneWidget);
    expect(find.text('玩家一'), findsWidgets);
    expect(find.text('玩家二'), findsWidgets);
  });

  testWidgets('练习模式渲染摆球与重打工具条', (tester) async {
    await pumpPage(
      tester,
      const GamePage(
        mode: GameMode.practice,
        difficulty: AiDifficulty.normal,
        humanSide: 0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('自由练习'), findsWidgets);
    expect(find.text('摆球'), findsOneWidget);
    expect(find.text('重打'), findsOneWidget);
    expect(find.text('击 球'), findsOneWidget);

    await tester.tap(find.text('摆球'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('完成摆球'), findsOneWidget);

    await tester.tap(find.text('完成摆球'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('摆球'), findsOneWidget);
  });

  testWidgets('点击击球后进入运动状态', (tester) async {
    final settings = await pumpPage(
      tester,
      const GamePage(
        mode: GameMode.twoPlayers,
        difficulty: AiDifficulty.normal,
        humanSide: 0,
      ),
    );
    expect(settings.showAimGuide, isTrue);

    await tester.tap(find.text('击 球'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('玩家一出杆'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('数据统计为空时显示引导文案', (tester) async {
    await pumpPage(tester, const StatsPage());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('数据统计'), findsOneWidget);
    expect(find.text('还没有可统计的对局'), findsOneWidget);
  });

  testWidgets('数据统计页汇总已保存对局', (tester) async {
    await MatchHistoryService.instance.add(sampleReplayRecord());
    await pumpPage(tester, const StatsPage());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('总览'), findsOneWidget);
    expect(find.text('总场次'), findsOneWidget);
    expect(find.text('双人场次'), findsOneWidget);
    expect(find.text('场均杆数'), findsOneWidget);
    expect(find.text('最近战绩'), findsOneWidget);
    expect(find.text('1.0'), findsOneWidget);
    expect(find.text('还没有人机对局'), findsOneWidget);
  });

  testWidgets('最近对局页可进入数据统计', (tester) async {
    await pumpPage(tester, const HistoryPage());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('数据统计'));
    await tester.pumpAndSettle();

    expect(find.text('还没有可统计的对局'), findsOneWidget);
  });
}
