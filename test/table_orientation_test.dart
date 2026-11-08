import 'package:chinese_eight_ball/pages/game_layout.dart';
import 'package:chinese_eight_ball/pages/table_orientation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(TableOrientation.resetForTests);
  tearDown(TableOrientation.resetForTests);

  test('窄屏横屏能明显放大球台时自动横屏', () {
    expect(TableOrientation.policyFor(const Size(390, 844)), TableOrientationPolicy.landscape);
    expect(TableOrientation.policyFor(const Size(360, 640)), TableOrientationPolicy.landscape);
    expect(TableOrientation.policyFor(const Size(844, 390)), TableOrientationPolicy.landscape);
    expect(GameLayout.landscapeGain(const Size(390, 844)), greaterThan(1.25));
    expect(GameLayout.landscapeGain(const Size(360, 640)), greaterThan(1.25));
  });

  test('平板与桌面保持系统方向，方形窄屏保持竖屏', () {
    expect(TableOrientation.policyFor(const Size(800, 1280)), TableOrientationPolicy.followSystem);
    expect(TableOrientation.policyFor(const Size(1280, 800)), TableOrientationPolicy.followSystem);
    expect(TableOrientation.policyFor(const Size(600, 600)), TableOrientationPolicy.portrait);
    expect(GameLayout.landscapeGain(const Size(600, 600)), lessThan(1.25));
  });

  testWidgets('进入窄屏球台锁定横屏全屏，离开后恢复系统方向', (tester) async {
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

    TableOrientation.attach();
    TableOrientation.sync(const Size(390, 844));
    await tester.pump();

    final orientation = calls
        .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
        .last;
    expect((orientation.arguments as List).cast<String>(), [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(
      calls.where((call) => call.method == 'SystemChrome.setEnabledSystemUIMode').last.arguments,
      'SystemUiMode.immersiveSticky',
    );

    calls.clear();
    TableOrientation.detach();
    await tester.pump();

    final restored = calls
        .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
        .last;
    expect((restored.arguments as List).cast<String>(), [
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.portraitDown',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(calls.last.arguments, 'SystemUiMode.edgeToEdge');
  });
}
