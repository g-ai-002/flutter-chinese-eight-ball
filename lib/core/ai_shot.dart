/// AI 难度预设：候选数量、瞄准误差与力度误差依次收紧。
enum AiDifficulty {
  easy('入门'),
  normal('进阶'),
  hard('高手'),
  custom('自定义');

  const AiDifficulty(this.label);

  final String label;

  AiTuning get tuning => switch (this) {
    easy => AiTuning.easy,
    normal => AiTuning.normal,
    hard => AiTuning.hard,
    custom => AiTuning.custom(0.5),
  };

  static AiDifficulty byName(String? name) =>
      values.firstWhere((value) => value.name == name, orElse: () => normal);
}

/// 实际传给 AI 的调参：候选线路数、瞄准误差与力度误差。
///
/// 预设难度直接取常量；自定义难度按 0~1 的强度在入门与高手之间线性插值。
class AiTuning {
  const AiTuning(
    this.label,
    this.candidateLimit,
    this.aimError,
    this.powerError,
  );

  static const AiTuning easy = AiTuning('入门', 4, 0.05, 0.16);
  static const AiTuning normal = AiTuning('进阶', 8, 0.016, 0.07);
  static const AiTuning hard = AiTuning('高手', 14, 0.005, 0.025);

  factory AiTuning.custom(double strength) {
    final t = strength.clamp(0.0, 1.0);
    return AiTuning(
      '自定义',
      (4 + 10 * t).round(),
      0.05 - 0.045 * t,
      0.16 - 0.135 * t,
    );
  }

  static AiTuning of(AiDifficulty difficulty, double strength) =>
      difficulty == AiDifficulty.custom
      ? AiTuning.custom(strength)
      : difficulty.tuning;

  final String label;
  final int candidateLimit;
  final double aimError;
  final double powerError;
}

/// AI 选定的一杆：击球角、力度、评分与用途，附带选中的目标球与袋口。
class AiShot {
  const AiShot({
    required this.angle,
    required this.power,
    required this.score,
    this.targetBallId,
    this.pocketIndex,
    this.isSafety = false,
  });

  final double angle;
  final double power;
  final double score;
  final int? targetBallId;
  final int? pocketIndex;

  /// 本杆是否为防守杆，用于日志与界面提示。
  final bool isSafety;
}
