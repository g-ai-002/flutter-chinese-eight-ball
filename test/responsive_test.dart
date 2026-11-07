import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/match_record.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/pages/game_page.dart';
import 'package:chinese_eight_ball/pages/home_page.dart';
import 'package:chinese_eight_ball/pages/replay_page.dart';
import 'package:chinese_eight_ball/pages/settings_page.dart';
import 'package:chinese_eight_ball/pages/stats_page.dart';
import 'package:chinese_eight_ball/pages/widgets/table_preview.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/match_history_service.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:chinese_eight_ball/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MatchRecord _replayRecord() {
  final balls = TableGeometry.rackBalls();
  final cue = balls.firstWhere((ball) => ball.isCue);
  return MatchRecord(
    id: 'replay-responsive',
    createdAt: DateTime(2026, 11, 5, 21),
    mode: 'vsAi',
    modeLabel: '人机对战',
    difficultyLabel: '高手',
    humanSide: 0,
    winner: 1,
    winnerName: '电脑',
    title: '电脑获胜',
    playerWin: false,
    endReason: '黑八提前落袋',
    shots: [
      ReplayShot(
        player: 0,
        balls: balls,
        angle: angleOf(cue.position, TableGeometry.footSpot),
        power: 0.9,
        calledPocket: null,
        result: '未进球，交换球权',
        potted: const [],
      ),
    ],
  );
}

/// 覆盖手机、折叠屏、平板与桌面窗口，确保没有溢出与布局异常。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  const sizes = <String, Size>{
    '小屏手机': Size(360, 640),
    '主流手机': Size(390, 844),
    '横屏手机': Size(844, 390),
    '折叠屏展开': Size(720, 900),
    '平板竖屏': Size(800, 1280),
    '桌面窗口': Size(1280, 800),
    '大屏桌面': Size(1920, 1080),
  };

  for (final entry in sizes.entries) {
    testWidgets('对局页适配${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
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

      expect(tester.takeException(), isNull);
      expect(find.text('击 球'), findsOneWidget);
      expect(find.byType(GamePage), findsOneWidget);
    });
  }

  testWidgets('小屏首页与设置页可滚动无溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = await StorageService.instance;
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
        child: MaterialApp(theme: buildLightTheme(), home: const HomePage()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
        child: MaterialApp(theme: buildLightTheme(), home: const SettingsPage()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('深色主题下对局页可渲染', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = await StorageService.instance;
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
        child: MaterialApp(
          theme: buildDarkTheme(),
          home: const GamePage(mode: GameMode.vsAi, difficulty: AiDifficulty.hard, humanSide: 0),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
  });

  for (final entry in const {
    '小屏手机': Size(360, 640),
    '折叠屏展开': Size(720, 900),
    '桌面窗口': Size(1280, 800),
  }.entries) {
    testWidgets('回放页适配${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final storage = await StorageService.instance;
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage),
          child: MaterialApp(
            theme: buildLightTheme(),
            home: ReplayPage(record: _replayRecord()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(tester.takeException(), isNull);
      expect(find.text('对局回放'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  }

  for (final entry in const {'横屏手机': Size(844, 390), '横屏小手机': Size(640, 360)}.entries) {
    testWidgets('回放页在${entry.key}优先保证球台', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final storage = await StorageService.instance;
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage),
          child: MaterialApp(
            theme: buildLightTheme(),
            home: ReplayPage(record: _replayRecord()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      expect(tester.takeException(), isNull);
      final table = tester.getSize(find.byKey(const Key('replay-table')));
      expect(table.width, greaterThan(300), reason: '${entry.key} 球台被压扁');
      expect(table.height, greaterThan(140), reason: '${entry.key} 球台被压扁');
      // 矮屏把逐杆条收进抽屉，避免挤压球台。
      expect(find.byTooltip('逐杆记录'), findsOneWidget);
    });
  }

  testWidgets('横屏首页缩略图限高，首屏可见玩法入口', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = await StorageService.instance;
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
        child: MaterialApp(theme: buildLightTheme(), home: const HomePage()),
      ),
    );
    await tester.pump();

    final preview = tester.getSize(find.byType(TablePreview));
    expect(preview.height, lessThan(170));
    expect(tester.getTopLeft(find.text('人机对战')).dy, lessThan(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面首页缩略图不超过 480 宽且首屏可见入口', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = await StorageService.instance;
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
        child: MaterialApp(theme: buildLightTheme(), home: const HomePage()),
      ),
    );
    await tester.pump();

    final preview = tester.getSize(find.byType(TablePreview));
    expect(preview.width, lessThanOrEqualTo(480));
    expect(tester.getBottomLeft(find.text('双人对战')).dy, lessThan(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('数据统计页在 2 倍字号下不溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    await MatchHistoryService.instance.add(_replayRecord());
    final storage = await StorageService.instance;
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
        child: MaterialApp(
          theme: buildLightTheme(),
          home: StatsPage(now: DateTime(2026, 11, 5)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
    expect(find.text('总场次'), findsOneWidget);
  });
}
