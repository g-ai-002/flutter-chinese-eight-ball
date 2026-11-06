import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/practice_preset.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('每个球型都有母球且摆位合法', () {
    expect(PracticePreset.rack.layout(), hasLength(16));
    final presets = PracticePreset.values.where(
      (preset) => preset != PracticePreset.rack,
    );
    for (final preset in presets) {
      final balls = preset.layout();
      expect(balls.where((ball) => ball.isCue), hasLength(1));
      expect(balls.length, greaterThanOrEqualTo(3));
      for (final ball in balls) {
        expect(
          TableGeometry.isValidBallPlacement(
            ball.position,
            obstacles: balls,
            ignoreId: ball.id,
          ),
          isTrue,
          reason: '${preset.label} 的 ${ball.id} 号球位置非法',
        );
      }
    }
  });

  test('练习球型覆盖长台直线与堆球', () {
    expect(PracticePreset.values, hasLength(6));
    expect(PracticePreset.long.label, '长台直线');
    expect(PracticePreset.long.layout(), hasLength(3));
    expect(PracticePreset.cluster.label, '堆球');
    expect(PracticePreset.cluster.layout(), hasLength(6));
  });

  test('练习模式切换球型后清空杆数与快照', () {
    final controller = MatchController(
      mode: GameMode.practice,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller.applyPracticePreset(PracticePreset.straight);
    expect(controller.balls, hasLength(4));
    expect(controller.phase, MatchPhase.aiming);
    expect(controller.shotCount, 0);
    expect(controller.practicePreset, PracticePreset.straight);
    expect(controller.log.last, '练习球型：直线球');

    controller.applyPracticePreset(PracticePreset.rack);
    expect(controller.balls, hasLength(16));
    expect(controller.practicePreset, PracticePreset.rack);
  });

  test('练习模式初始球型为标准开球，摆球后取消标记', () {
    final controller = MatchController(
      mode: GameMode.practice,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    expect(controller.practicePreset, PracticePreset.rack);
    controller.beginBallEdit();
    expect(controller.practicePreset, isNull);
  });

  test('对局模式忽略球型切换', () {
    final controller = MatchController(
      mode: GameMode.twoPlayers,
      autoPlayAi: false,
    );
    addTearDown(controller.dispose);

    controller.applyPracticePreset(PracticePreset.cut);
    expect(controller.balls, hasLength(16));
    expect(controller.log.last, isNot(contains('练习球型')));
  });
}
