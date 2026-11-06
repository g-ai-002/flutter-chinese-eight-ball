import 'package:chinese_eight_ball/core/ai.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:chinese_eight_ball/theme/table_skin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  test('偏好默认值与写入', () async {
    final storage = await StorageService.instance;
    expect(storage.darkMode, isFalse);
    expect(storage.difficulty, AiDifficulty.normal);
    expect(storage.humanSide, 0);
    expect(storage.soundEnabled, isTrue);
    expect(storage.showAimGuide, isTrue);

    await storage.setDarkMode(true);
    await storage.setDifficulty(AiDifficulty.hard);
    await storage.setHumanSide(1);
    await storage.setTableSkinId('midnight');

    expect(storage.darkMode, isTrue);
    expect(storage.difficulty, AiDifficulty.hard);
    expect(storage.humanSide, 1);
    expect(storage.tableSkinId, 'midnight');
  });

  test('自定义 AI 强度默认中等并可收敛到边界', () async {
    final storage = await StorageService.instance;
    expect(storage.aiStrength, 0.5);

    await storage.setAiStrength(1.4);
    expect(storage.aiStrength, 1.0);

    await storage.setDifficulty(AiDifficulty.custom);
    expect(storage.difficulty, AiDifficulty.custom);
    expect(storage.aiStrength, 1.0);
  });

  test('未知难度与配色回退到默认值', () async {
    SharedPreferences.setMockInitialValues({
      'difficulty': 'unknown',
      'table_skin': 'missing',
    });
    StorageService.resetForTests();
    final storage = await StorageService.instance;
    expect(storage.difficulty, AiDifficulty.normal);
    expect(tableSkinOf(storage.tableSkinId).id, 'emerald');
  });

  test('设置提供者写入后通知监听者', () async {
    final storage = await StorageService.instance;
    final provider = SettingsProvider(storage);
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.setShowAimGuide(false);
    expect(provider.showAimGuide, isFalse);
    expect(notified, 1);
    expect(storage.showAimGuide, isFalse);
  });
}
