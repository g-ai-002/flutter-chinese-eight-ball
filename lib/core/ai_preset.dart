import 'ai_shot.dart';

/// 配置码承载的 AI 设置：难度与自定义强度。
typedef AiPreset = ({AiDifficulty difficulty, double strength});

/// AI 配置分享码：`CEB1-难度-强度千分比`，例如 `CEB1-进阶-620`。
///
/// 只包含难度与自定义强度，不携带设备信息，可离线复制粘贴。
class AiPresetCode {
  AiPresetCode._();

  static const String prefix = 'CEB1';
  static const int _scale = 1000;

  static String encode(AiDifficulty difficulty, double strength) {
    final value = (strength.clamp(0.0, 1.0) * _scale).round();
    return '$prefix-${difficulty.label}-$value';
  }

  /// 解析配置码；格式不合法返回 null，强度越界自动收敛到 0~1。
  static AiPreset? decode(String raw) {
    final parts = raw.trim().split('-');
    if (parts.length != 3 || parts.first.toUpperCase() != prefix) return null;
    final difficulty = AiDifficulty.byLabel(parts[1]);
    final strength = int.tryParse(parts[2]);
    if (difficulty == null || strength == null) return null;
    return (difficulty: difficulty, strength: (strength / _scale).clamp(0.0, 1.0).toDouble());
  }
}
