import 'package:chinese_eight_ball/utils/startup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('启动延后任务等首帧渲染完成后才执行', (tester) async {
    var ran = false;
    runAfterFirstFrame(() async => ran = true);
    expect(ran, isFalse, reason: '日志与音频初始化不能占用启动关键路径');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(ran, isTrue);
  });
}
