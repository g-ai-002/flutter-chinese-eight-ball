import 'package:chinese_eight_ball/app.dart';
import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/pages/game_page.dart';
import 'package:chinese_eight_ball/pages/help_page.dart';
import 'package:chinese_eight_ball/pages/home_page.dart';
import 'package:chinese_eight_ball/pages/settings_page.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(find.text('玩法规则'), findsOneWidget);
    expect(find.textContaining('v0.1.0'), findsOneWidget);
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
}
