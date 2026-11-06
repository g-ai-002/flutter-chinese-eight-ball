import 'match_record.dart';
import 'shot_tally.dart';

/// 单一 AI 难度的战绩。
class DifficultyStats {
  const DifficultyStats({
    required this.label,
    required this.matches,
    required this.wins,
  });

  /// 按难度聚合人机对局：已知难度按「入门 → 进阶 → 高手」排列，
  /// 其他标签追加在后面，保证统计页顺序稳定。
  static List<DifficultyStats> breakdown(Iterable<MatchRecord> aiRecords) {
    final byLabel = <String, ({int matches, int wins})>{};
    for (final record in aiRecords) {
      final current = byLabel[record.difficultyLabel];
      byLabel[record.difficultyLabel] = (
        matches: (current?.matches ?? 0) + 1,
        wins: (current?.wins ?? 0) + (record.playerWin ? 1 : 0),
      );
    }
    const knownLabels = ['入门', '进阶', '高手', '自定义'];
    final labels = [
      ...knownLabels.where(byLabel.containsKey),
      ...byLabel.keys.where((label) => !knownLabels.contains(label)),
    ];
    return [
      for (final label in labels)
        DifficultyStats(
          label: label,
          matches: byLabel[label]!.matches,
          wins: byLabel[label]!.wins,
        ),
    ];
  }

  final String label;
  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;
}

/// 单场走势：进球率用于柱高，人机对局额外记录胜负。
class TrendPoint {
  const TrendPoint({
    required this.createdAt,
    required this.shots,
    required this.potted,
    required this.win,
  });

  final DateTime createdAt;
  final int shots;
  final int potted;

  /// 仅人机对局有胜负，双人对局为 null。
  final bool? win;

  double get potRate => shots == 0 ? 0 : potted / shots;
}

/// 本机对局记录的聚合结果，供数据统计页展示。
///
/// 只读取已完成的对局记录，不修改也不上传任何数据；输入顺序不限，
/// 内部按时间从新到旧排序，最近战绩与难度顺序因此保持稳定。
class MatchStats {
  const MatchStats({
    required this.matches,
    required this.aiMatches,
    required this.aiWins,
    required this.twoPlayerMatches,
    required this.shots,
    required this.potted,
    required this.bestShotPotted,
    required this.bestStreak,
    required this.difficulties,
    required this.recentAiResults,
    required this.trend,
  });

  factory MatchStats.fromRecords(Iterable<MatchRecord> records) {
    final all = [...records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final aiRecords = [
      for (final record in all)
        if (record.isVersusAi) record,
    ];
    final tally = ShotTally.of(all);

    return MatchStats(
      matches: all.length,
      aiMatches: aiRecords.length,
      aiWins: aiRecords.where((record) => record.playerWin).length,
      twoPlayerMatches: all.where((record) => record.isTwoPlayers).length,
      shots: tally.shots,
      potted: tally.potted,
      bestShotPotted: tally.bestShotPotted,
      bestStreak: tally.bestStreak,
      difficulties: DifficultyStats.breakdown(aiRecords),
      recentAiResults: [
        for (final record in aiRecords.take(5)) record.playerWin,
      ],
      trend: [
        for (final record in all.take(8).toList().reversed)
          TrendPoint(
            createdAt: record.createdAt,
            shots: record.shots.length,
            potted: record.shots.fold(
              0,
              (sum, shot) => sum + shot.potted.where((id) => id != 0).length,
            ),
            win: record.isVersusAi ? record.playerWin : null,
          ),
      ],
    );
  }

  /// 已保存的对局总数（人机 + 双人）。
  final int matches;
  final int aiMatches;
  final int aiWins;
  final int twoPlayerMatches;

  /// 所有对局累计杆数与进球数（不含母球落袋）。
  final int shots;
  final int potted;

  /// 单杆最多进球数与单场最长连续进球杆数。
  final int bestShotPotted;
  final int bestStreak;

  final List<DifficultyStats> difficulties;

  /// 最近 5 场人机对局的胜负，按时间从新到旧。
  final List<bool> recentAiResults;

  /// 最近 8 场对局走势，按时间从旧到新，供图表绘制。
  final List<TrendPoint> trend;

  bool get isEmpty => matches == 0;

  int get aiLosses => aiMatches - aiWins;

  double get aiWinRate => aiMatches == 0 ? 0 : aiWins / aiMatches;

  double get averageShots => matches == 0 ? 0 : shots / matches;

  /// 进球率：每杆平均打进的目标球数（0~1 之间不保证，可能一杆多球）。
  double get potRate => shots == 0 ? 0 : potted / shots;
}
