import 'package:chinese_eight_ball/core/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('预设难度映射到对应调参', () {
    expect(AiTuning.of(AiDifficulty.easy, 0.9), AiTuning.easy);
    expect(AiTuning.of(AiDifficulty.normal, 0.1), AiTuning.normal);
    expect(AiTuning.of(AiDifficulty.hard, 0.1), AiTuning.hard);
  });

  test('自定义强度在入门与高手之间插值', () {
    final weak = AiTuning.custom(0);
    final strong = AiTuning.custom(1);
    expect(weak.label, '自定义');
    expect(weak.candidateLimit, 4);
    expect(weak.aimError, closeTo(0.05, 1e-9));
    expect(strong.candidateLimit, 14);
    expect(strong.aimError, closeTo(0.005, 1e-9));
    expect(AiTuning.custom(0.5).candidateLimit, 9);
  });

  test('强度超出范围时收敛到边界', () {
    expect(AiTuning.custom(-3).candidateLimit, 4);
    expect(AiTuning.custom(9).powerError, closeTo(0.025, 1e-9));
  });

  test('自定义难度按强度取值', () {
    final tuning = AiTuning.of(AiDifficulty.custom, 0.8);
    expect(tuning.label, '自定义');
    expect(tuning.aimError, lessThan(AiTuning.normal.aimError));
  });
}
