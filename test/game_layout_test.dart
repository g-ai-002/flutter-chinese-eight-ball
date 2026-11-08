import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/flame/table_layout.dart';
import 'package:chinese_eight_ball/pages/game_layout.dart';
import 'package:chinese_eight_ball/pages/game_page.dart';
import 'package:chinese_eight_ball/pages/table_orientation.dart';
import 'package:chinese_eight_ball/pages/widgets/game_hud.dart';
import 'package:chinese_eight_ball/pages/widgets/power_control.dart';
import 'package:chinese_eight_ball/pages/widgets/practice_toolbar.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:chinese_eight_ball/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  '横屏小手机': Size(640, 360),
  '横屏旧机型': Size(568, 320),
  '超小屏手机': Size(320, 480),
  '折叠屏展开': Size(720, 900),
  '小尺寸窗口': Size(1024, 600),
  '桌面窗口': Size(1280, 800),
  '大屏桌面': Size(1920, 1080),
  '超宽屏桌面': Size(2560, 1440),
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

/// 球台在一个方向上铺满整页（另一边受球台比例限制）。
bool fillsPage(GameLayout layout) =>
    layout.tableSize.width >= layout.page.width - 0.5 ||
    layout.tableSize.height >= layout.page.height - 0.5;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
    TableOrientation.resetForTests();
  });

  group('对局页浮层几何', () {
    for (final entry in sizes.entries) {
      test('${entry.key}：球台铺满可用区域且不越界', () {
        final page = entry.value;
        final layout = GameLayout(page);
        expect(layout.tableRect.left, greaterThanOrEqualTo(0));
        expect(layout.tableRect.top, greaterThanOrEqualTo(0));
        expect(layout.tableRect.right, lessThanOrEqualTo(page.width));
        expect(layout.tableRect.bottom, lessThanOrEqualTo(page.height));
        if (layout.immersive) {
          // 横屏沉浸：球台吃满整页，浮层半透明叠在球台上下沿。
          expect(layout.tableSize, TableLayout.fit(page), reason: '${entry.key} 球台没有吃满整页');
          expect(layout.tableRect.center.dx, closeTo(page.width / 2, 0.5));
          expect(layout.tableRect.center.dy, closeTo(page.height / 2, 0.5));
          expect(layout.info, isNull);
          return;
        }
        for (final hud in [layout.header, layout.dock, if (layout.info != null) layout.info!]) {
          expect(layout.tableRect.overlaps(hud), isFalse, reason: '${entry.key} 浮层压到球台');
        }
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

    test('窄屏把提示条悬浮在球台上方，宽屏把提示内联到顶部条', () {
      final phone = GameLayout(const Size(390, 844));
      expect(phone.inline, isFalse);
      expect(phone.compact, isFalse);
      expect(phone.info, isNotNull);
      expect(phone.singleRow, isFalse);
      expect(phone.info!.bottom, closeTo(phone.tableRect.top - GameLayout.gap, 0.001));
      expect(phone.info!.top, greaterThanOrEqualTo(phone.header.bottom));
      expect(phone.tableRect.center.dy, closeTo(phone.page.height / 2, 0.5));

      final desktop = GameLayout(const Size(1280, 800));
      expect(desktop.inline, isTrue);
      expect(desktop.compact, isFalse);
      expect(desktop.info, isNull);
      expect(desktop.singleRow, isTrue);

      final landscape = GameLayout(const Size(844, 390));
      expect(landscape.inline, isTrue);
      expect(landscape.compact, isTrue);
      expect(landscape.singleRow, isTrue);
      expect(landscape.immersive, isTrue);
      expect(landscape.info, isNull);
    });

    test('球台在页面正中显示，不被提示条挤偏', () {
      for (final page in const [Size(390, 844), Size(360, 640), Size(720, 900), Size(800, 1280)]) {
        final layout = GameLayout(page);
        expect(layout.tableRect.center.dx, closeTo(page.width / 2, 0.5), reason: '$page 水平未居中');
        expect(layout.tableRect.center.dy, closeTo(page.height / 2, 0.5), reason: '$page 垂直未居中');
      }
    });

    test('横屏与矮窗口进入紧凑模式，不再预留提示条', () {
      for (final page in const [Size(844, 390), Size(640, 360), Size(568, 320), Size(720, 520)]) {
        final layout = GameLayout(page);
        expect(layout.compact, isTrue, reason: '$page 应使用紧凑布局');
        expect(layout.info, isNull, reason: '$page 不应预留提示条');
        expect(layout.header.height, lessThanOrEqualTo(GameLayout.compactHeaderHeight));
        expect(fillsPage(layout), isTrue, reason: '$page 球台应吃满屏幕');
      }
      for (final page in const [Size(390, 844), Size(800, 1280), Size(1280, 800)]) {
        expect(GameLayout(page).compact, isFalse, reason: '$page 不应使用紧凑布局');
        expect(GameLayout(page).immersive, isFalse, reason: '$page 不应使用沉浸布局');
      }
    });

    test('横屏球台吃满整页，面积明显大于为浮层让位的布局', () {
      for (final page in const [Size(844, 390), Size(640, 360), Size(568, 320)]) {
        final layout = GameLayout(page);
        expect(layout.immersive, isTrue, reason: '$page 应进入沉浸布局');
        // 球台在一个方向上铺满整页，另一边只受球台比例限制。
        expect(
          layout.tableSize.width >= page.width - 0.5 ||
              layout.tableSize.height >= page.height - 0.5,
          isTrue,
          reason: '$page 球台没有铺满整页',
        );
        final reserved = TableLayout.fit(
          Size(page.width - 16, page.height - 16 - GameLayout.compactHeaderHeight - 56 - 16),
        );
        expect(
          layout.tableSize.width * layout.tableSize.height,
          greaterThan(reserved.width * reserved.height * 1.3),
          reason: '$page 沉浸布局球台提升不足',
        );
        // 顶部条与操作条叠在球台上，不改变球台尺寸。
        expect(layout.header.overlaps(layout.tableRect), isTrue);
        expect(layout.dock.overlaps(layout.tableRect), isTrue);
        expect(layout.header.top, closeTo(GameLayout.pagePadding, 0.001));
        expect(layout.dock.bottom, closeTo(page.height - GameLayout.pagePadding, 0.001));
        expect(layout.dock.width, lessThanOrEqualTo(GameLayout.dockMaxWidth));
        expect(layout.dock.center.dx, closeTo(page.width / 2, 0.5));
      }
    });

    test('紧凑模式在 480 像素宽即可单行排布力度控制', () {
      expect(GameLayout(const Size(480, 320)).singleRow, isTrue);
      expect(GameLayout(const Size(479, 320)).singleRow, isFalse);
      expect(GameLayout(const Size(520, 844)).singleRow, isFalse);
      expect(GameLayout(const Size(560, 844)).singleRow, isTrue);
    });

    test('极小窗口球台不溢出且保持可见', () {
      for (final page in const [Size(320, 240), Size(480, 240), Size(240, 320)]) {
        final layout = GameLayout(page);
        expect(layout.tableRect.left, greaterThanOrEqualTo(0), reason: '$page 球台越界');
        expect(layout.tableRect.top, greaterThanOrEqualTo(0), reason: '$page 球台越界');
        expect(layout.tableRect.right, lessThanOrEqualTo(page.width), reason: '$page 球台越界');
        expect(layout.tableRect.bottom, lessThanOrEqualTo(page.height), reason: '$page 球台越界');
        expect(layout.tableSize.width, greaterThan(0), reason: '$page 球台消失');
        expect(layout.panel.right, lessThanOrEqualTo(page.width));
        expect(layout.panel.left, greaterThanOrEqualTo(0));
      }
    });

    test('球台缩放不超出可用区域', () {
      for (final available in const [Size(800, 200), Size(300, 1000), Size(200, 120)]) {
        final size = TableLayout.fit(available);
        expect(size.width, lessThanOrEqualTo(available.width));
        expect(size.height, lessThanOrEqualTo(available.height));
        expect(size.width / size.height, closeTo(TableLayout.aspectRatio, 0.001));
      }
      expect(TableLayout.fit(Size.zero), Size.zero);
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

  for (final entry in const {'横屏小手机': Size(640, 360), '横屏旧机型': Size(568, 320)}.entries) {
    testWidgets('${entry.key}：提示内联到顶部条，球台保持可用', (tester) async {
      await pumpGame(tester, entry.value);
      expect(find.byType(GameInfoPill), findsNothing);
      expect(find.text('拖动球台瞄准，调整力度后击球'), findsWidgets);
      expect(find.text('你的回合'), findsOneWidget);
      expect(find.text('击 球'), findsOneWidget);
      final table = tableSizeOf(tester);
      expect(table.width, greaterThan(300));
      expect(table.height, greaterThan(150));
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in const {
    '横屏手机': Size(844, 390),
    '横屏小手机': Size(640, 360),
    '横屏旧机型': Size(568, 320),
  }.entries) {
    testWidgets('${entry.key}：球台吃满屏幕，浮层叠在球台上', (tester) async {
      await pumpGame(tester, entry.value);
      final table = tester.getRect(find.byKey(const Key('game-table')));
      expect(table.left, greaterThanOrEqualTo(0));
      expect(table.top, greaterThanOrEqualTo(0));
      expect(table.right, lessThanOrEqualTo(entry.value.width));
      expect(table.bottom, lessThanOrEqualTo(entry.value.height));
      // 球台在一个方向上铺满整页，另一边只受球台比例限制。
      final fills =
          (table.width - entry.value.width).abs() < 0.5 ||
          (table.height - entry.value.height).abs() < 0.5;
      expect(fills, isTrue, reason: '${entry.key} 球台没有吃满屏幕');
      expect(table.height, greaterThan(entry.value.height * 0.9));
      // 顶部条与操作条都叠在球台上，球台不再为浮层让位。
      final header = tester.getRect(find.byType(GameHeader));
      expect(header.overlaps(table), isTrue);
      expect(header.top, closeTo(GameLayout.pagePadding, 0.5));
      expect(tester.getRect(find.byType(PowerControl)).width, lessThanOrEqualTo(704));
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in const {'横屏手机': Size(844, 390), '横屏小手机': Size(640, 360)}.entries) {
    testWidgets('${entry.key}：叠在球台上的浮层只留 5% 底板', (tester) async {
      await pumpGame(tester, entry.value);
      for (final surface in tester.widgetList<HudSurface>(find.byType(HudSurface))) {
        expect(surface.opacity, HudSurface.immersiveOpacity, reason: '${entry.key} 浮层仍挡住球台');
      }
      final header = tester.widget<Material>(
        find.descendant(of: find.byType(GameHeader), matching: find.byType(Material)).first,
      );
      expect(header.color!.a, closeTo(HudSurface.immersiveOpacity, 0.001));
      // 底板几乎全透明，文字改用深色主题的浅色，台呢上还能看清。
      final text = tester.widget<RichText>(
        find.descendant(of: find.text('双人对战'), matching: find.byType(RichText)),
      );
      expect(text.text.style?.color?.computeLuminance(), greaterThan(0.5));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('竖屏浮层不叠球台，保持原有底板', (tester) async {
    await pumpGame(tester, const Size(390, 844));
    final dock = find.ancestor(of: find.byType(PowerControl), matching: find.byType(HudSurface));
    expect(tester.widget<HudSurface>(dock).opacity, 0.94);
    final material = tester.widget<Material>(
      find.descendant(of: dock, matching: find.byType(Material)).first,
    );
    expect(material.color!.a, closeTo(0.94, 0.001));
  });

  testWidgets('横屏练习工具条的按钮同样只留 5% 底板', (tester) async {
    await pumpGame(tester, const Size(844, 390), mode: GameMode.practice);
    expect(tester.widget<PracticeToolbar>(find.byType(PracticeToolbar)).translucent, isTrue);
    final chip = tester.widgetList<Material>(
      find.descendant(of: find.byType(PracticeToolbar), matching: find.byType(Material)),
    );
    expect(chip.first.color!.a, closeTo(HudSurface.immersiveOpacity, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('横屏练习工具条让开顶部浮层', (tester) async {
    await pumpGame(tester, const Size(568, 320), mode: GameMode.practice);
    final header = tester.getRect(find.byType(GameHeader));
    final toolbar = tester.getRect(find.byType(PracticeToolbar));
    expect(toolbar.top, greaterThanOrEqualTo(header.bottom));
    expect(toolbar.bottom, lessThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('横屏留白足够时练习工具条不越出球台', (tester) async {
    await pumpGame(tester, const Size(720, 520), mode: GameMode.practice);
    final table = tester.getRect(find.byKey(const Key('game-table')));
    final toolbar = tester.getRect(find.byType(PracticeToolbar));
    expect(toolbar.top, greaterThanOrEqualTo(table.top));
    expect(toolbar.bottom, lessThanOrEqualTo(table.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('练习工具条在窄球台上不越界', (tester) async {
    await pumpGame(tester, const Size(568, 320), mode: GameMode.practice);
    expect(find.text('摆球'), findsOneWidget);
    expect(find.text('球型'), findsOneWidget);
    expect(find.text('重打'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final table = tester.getRect(find.byKey(const Key('game-table')));
    expect(table.left, greaterThanOrEqualTo(0));
    expect(table.right, lessThanOrEqualTo(568));
  });

  for (final entry in const {
    '小屏手机': Size(360, 640),
    '横屏小手机': Size(640, 360),
    '桌面窗口': Size(1280, 800),
  }.entries) {
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

  testWidgets('关闭对局页后恢复系统方向，不残留全屏', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpGame(tester, const Size(390, 844));
    bool sent(String orientation) => calls.any(
      (call) =>
          call.method == 'SystemChrome.setPreferredOrientations' &&
          (call.arguments as List).first == orientation,
    );
    expect(sent('DeviceOrientation.landscapeLeft'), isTrue, reason: '窄屏应对局进入横屏');

    calls.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(sent('DeviceOrientation.portraitUp'), isTrue, reason: '离开后应恢复系统方向');
    expect(calls.any((call) => call.arguments == 'SystemUiMode.edgeToEdge'), isTrue);
    expect(find.byType(GamePage), findsNothing);
  });
}
