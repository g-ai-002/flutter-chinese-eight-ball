import 'ai_shot.dart';

/// AI 配置分享码：`CEB1-难度-强度千分比`，例如 `CEB1-进阶-620`。
///
/// 只包含难度与自定义强度，不携带设备信息，可离线复制粘贴。
class AiPresetCode {
  AiPresetCode._();

  static const String _prefix = 'CEB1';

  static String encode(AiDifficulty difficulty, double strength) {
    final value = (strength.clamp(0.0, 1.0) * 1000).round();
    return '$_prefix-${difficulty.label}-$value';
  }

  /// 解析配置码；格式不合法返回 null，强度越界自动收敛到 0~1。
  static ({AiDifficulty difficulty, double strength})? decode(String raw) {
    final parts = raw.trim().split('-');
    if (parts.length != 3 || parts.first.toUpperCase() != _prefix) return null;
    AiDifficulty? difficulty;
    for (final value in AiDifficulty.values) {
      if (value.label == parts[1] || value.name == parts[1].toLowerCase()) {
        difficulty = value;
      }
    }
    final strength = int.tryParse(parts[2]);
    if (difficulty == null || strength == null) return null;
    return (
      difficulty: difficulty,
      strength: (strength / 1000).clamp(0.0, 1.0).toDouble(),
    );
  }
}
