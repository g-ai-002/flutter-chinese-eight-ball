import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/flame/table_layout.dart';
import 'package:chinese_eight_ball/pages/game_layout.dart';
import 'package:chinese_eight_ball/pages/game_page.dart';
import 'package:chinese_eight_ball/pages/widgets/game_hud.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:chinese_eight_ball/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 0.7.3 之前的球台尺寸：顶部 AppBar 固定 52，窄屏底部工具区约 190，宽屏右侧栏 320。
Size legacyTableSize(Size page) {
  final body = Size(page.width, page.height - 52);
  if (body.width >= 980 && body.height >= 520) {
    return TableLayout.fit(Size(body.width - 352, body.height - 100));
  }
  return TableLayout.fit(Size(body.width - 24, body.height - 190));
}

const sizes = <String, Size>{
  '小屏手机': Size(360, 640),
  '主流手机': Size(390, 844),
  '横屏手机': Size(844, 390),
  '折叠屏展开': Size(720, 900),
  '桌面窗口': Size(1280, 800),
  '大屏桌面': Size(1920, 1080),
};

Future<void> pumpGame(WidgetTester tester, Size size, {GameMode mode = GameMode.twoPlayers}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final storage = await StorageService.instance;
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider(storage),
      child: MaterialApp(
        theme: buildLightTheme(),
        home: GamePage(mode: mode, difficulty: AiDifficulty.normal, humanSide: 0),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 120));
}

Size tableSizeOf(WidgetTester tester) => tester.getSize(find.byKey(const Key('game-table')));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  group('对局页浮层几何', () {
    for (final entry in sizes.entries) {
      test('${entry.key}：球台贴满中段且不与浮层重叠', () {
        final page = entry.value;
        final layout = GameLayout(page);
        for (final hud in [layout.header, layout.dock, if (layout.info != null) layout.info!]) {
          expect(layout.tableRect.overlaps(hud), isFalse, reason: '${entry.key} 浮层压到球台');
        }
        expect(layout.tableRect.left, greaterThanOrEqualTo(0));
        expect(layout.tableRect.top, greaterThanOrEqualTo(0));
        expect(layout.tableRect.right, lessThanOrEqualTo(page.width));
        expect(layout.tableRect.bottom, lessThanOrEqualTo(page.height));
        // 球台至少在一个方向上占满可用区域，另一方向居中留白。
        final core = Rect.fromLTRB(
          GameLayout.pagePadding,
          layout.header.bottom + GameLayout.gap,
          page.width - GameLayout.pagePadding,
          layout.dock.top - GameLayout.gap,
        );
        final fillWidth = layout.tableSize.width >= core.width - 0.5;
        final fillHeight = layout.tableSize.height >= core.height - 0.5;
        expect(fillWidth || fillHeight, isTrue, reason: '${entry.key} 球台没有占满可用空间');
        expect(layout.tableRect.center.dx, closeTo(core.center.dx, 0.5));
      });

      test('${entry.key}：球台面积不小于旧布局', () {
        final layout = GameLayout(entry.value);
        final legacy = legacyTableSize(entry.value);
        final before = legacy.width * legacy.height;
        final after = layout.tableSize.width * layout.tableSize.height;
        expect(after, greaterThanOrEqualTo(before));
      });
    }

    test('桌面与横屏球台明显变大', () {
      for (final page in const [Size(1280, 800), Size(1920, 1080), Size(844, 390)]) {
        final layout = GameLayout(page);
        final legacy = legacyTableSize(page);
        expect(layout.tableSize.width, greaterThan(legacy.width));
        expect(layout.tableSize.height, greaterThan(legacy.height));
        final before = legacy.width * legacy.height;
        final after = layout.tableSize.width * layout.tableSize.height;
        expect(after / before, greaterThan(1.25), reason: '$page 球台面积提升不足');
      }
    });

    test('球局浮层贴在右侧且不越界', () {
      for (final page in const [Size(390, 844), Size(1280, 800)]) {
        final layout = GameLayout(page);
        expect(layout.panel.width, lessThanOrEqualTo(GameLayout.panelMaxWidth));
        expect(layout.panel.right, closeTo(page.width - GameLayout.pagePadding, 0.001));
        expect(layout.panel.top, closeTo(layout.header.bottom + GameLayout.gap, 0.001));
        expect(layout.panel.bottom, closeTo(layout.dock.top - GameLayout.gap, 0.001));
      }
    });

    test('窄屏在球台下方留出提示条，宽屏把提示内联到顶部条', () {
      final phone = GameLayout(const Size(390, 844));
      expect(phone.inline, isFalse);
      expect(phone.info, isNotNull);
      expect(phone.singleRow, isFalse);
      expect(phone.info!.top, closeTo(phone.tableRect.bottom + GameLayout.gap, 0.001));
      expect(phone.info!.bottom, lessThanOrEqualTo(phone.dock.top));

      final desktop = GameLayout(const Size(1280, 800));
      expect(desktop.inline, isTrue);
      expect(desktop.info, isNull);
      expect(desktop.singleRow, isTrue);

      final landscape = GameLayout(const Size(844, 390));
      expect(landscape.inline, isTrue);
      expect(landscape.singleRow, isTrue);
    });
  });

  group('球台尺寸稳定', () {
    for (final entry in const {
      '手机竖屏': Size(390, 844),
      '横屏手机': Size(844, 390),
      '桌面窗口': Size(1280, 800),
    }.entries) {
      testWidgets('${entry.key}：提示与球局浮层不影响球台', (tester) async {
        await pumpGame(tester, entry.value);
        final initial = tableSizeOf(tester);

        // 出杆后提示与上一杆文案都会变化，球台尺寸必须保持不变。
        await tester.tap(find.text('击 球'));
        await tester.pump(const Duration(milliseconds: 60));
        expect(tableSizeOf(tester), initial);

        await tester.tap(find.byTooltip('球局信息'));
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.text('球局'), findsOneWidget);
        expect(tableSizeOf(tester), initial);

        await tester.tap(find.byTooltip('收起球局'));
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.text('球局'), findsNothing);
        expect(tableSizeOf(tester), initial);
      });
    }
  });

  testWidgets('窄屏显示悬浮提示条，宽屏不占用球台下方空间', (tester) async {
    await pumpGame(tester, const Size(390, 844));
    expect(find.byType(GameInfoPill), findsOneWidget);
    expect(find.text('你的回合'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpGame(tester, const Size(1280, 800));
    expect(find.byType(GameInfoPill), findsNothing);
    expect(find.text('你的回合'), findsOneWidget);
    expect(find.text('玩家一'), findsOneWidget);
    expect(find.text('玩家二'), findsOneWidget);
  });

  testWidgets('练习模式不重复展示玩家条', (tester) async {
    await pumpGame(tester, const Size(390, 844), mode: GameMode.practice);
    expect(find.text('自由练习'), findsWidgets);
    expect(find.text('摆球'), findsOneWidget);
    expect(find.text('击 球'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in const {'小屏手机': Size(360, 640), '桌面窗口': Size(1280, 800)}.entries) {
    for (final scale in const [1.3, 2.0]) {
      testWidgets('${entry.key} ${scale}x 字号下浮层不溢出', (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpGame(tester, entry.value);
        expect(tester.takeException(), isNull);
        expect(find.text('击 球'), findsOneWidget);
      });
    }
  }
}
