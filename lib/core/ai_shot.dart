/// AI 难度：候选数量、瞄准误差与力度误差依次收紧。
enum AiDifficulty {
  easy('入门', 4, 0.05, 0.16),
  normal('进阶', 8, 0.016, 0.07),
  hard('高手', 14, 0.005, 0.025);

  const AiDifficulty(
    this.label,
    this.candidateLimit,
    this.aimError,
    this.powerError,
  );

  final String label;
  final int candidateLimit;
  final double aimError;
  final double powerError;

  static AiDifficulty byName(String? name) =>
      values.firstWhere((value) => value.name == name, orElse: () => normal);
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
