import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/flame/eight_ball_game.dart';
import 'package:chinese_eight_ball/providers/settings_provider.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('静止画面空闲后挂起引擎，交互后立即恢复', () async {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
    final settings = SettingsProvider(await StorageService.instance);
    final controller = MatchController(mode: GameMode.practice, autoPlayAi: false);
    addTearDown(controller.dispose);
    final game = EightBallGame(controller: controller, settings: settings);

    for (var i = 0; i < 30; i++) {
      game.update(1 / 60);
    }
    expect(game.paused, isTrue, reason: '瞄准阶段静止半秒后应挂起');

    game.wake();
    expect(game.paused, isFalse);

    for (var i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    expect(game.paused, isFalse, reason: '交互后重新开始计时，不应立刻挂起');
  });

  test('开球过程中不挂起渲染循环', () async {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
    final settings = SettingsProvider(await StorageService.instance);
    final controller = MatchController(mode: GameMode.practice, autoPlayAi: false);
    addTearDown(controller.dispose);
    final game = EightBallGame(controller: controller, settings: settings);

    controller.shoot();
    for (var i = 0; i < 30 && controller.phase == MatchPhase.shooting; i++) {
      game.update(1 / 60);
    }
    expect(game.paused, isFalse);
  });
}
