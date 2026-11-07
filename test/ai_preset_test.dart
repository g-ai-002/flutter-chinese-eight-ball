import 'package:chinese_eight_ball/core/ai_preset.dart';
import 'package:chinese_eight_ball/core/ai_shot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('配置码可往返解析每种难度', () {
    for (final difficulty in AiDifficulty.values) {
      final code = AiPresetCode.encode(difficulty, 0.62);
      expect(code, 'CEB1-${difficulty.label}-620');
      final decoded = AiPresetCode.decode(code);
      expect(decoded?.difficulty, difficulty);
      expect(decoded?.strength, closeTo(0.62, 1e-9));
    }
  });

  test('配置码接受英文难度名并收敛强度', () {
    expect(
      AiPresetCode.decode('ceb1-hard-2500')?.difficulty,
      AiDifficulty.hard,
    );
    expect(AiPresetCode.decode('CEB1-easy-0')?.strength, 0);
    expect(AiPresetCode.decode('CEB1-normal-1500')?.strength, 1);
  });

  test('非法配置码返回 null', () {
    const invalid = [
      '',
      'CEB1',
      'CEB2-hard-500',
      'CEB1-unknown-500',
      'CEB1-hard-x',
      'CEB1-hard',
    ];
    for (final raw in invalid) {
      expect(AiPresetCode.decode(raw), isNull, reason: raw);
    }
  });
}
