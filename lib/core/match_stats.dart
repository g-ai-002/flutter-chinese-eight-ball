import 'match_record.dart';

/// 单一 AI 难度的战绩。
class DifficultyStats {
  const DifficultyStats({
    required this.label,
    required this.matches,
    required this.wins,
  });

  final String label;
  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;
}

/// 本机对局记录的聚合结果，供数据统计页展示。
///
/// 只读取已完成的对局记录，不修改也不上传任何数据。
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
  });

  factory MatchStats.fromRecords(Iterable<MatchRecord> records) {
    final all = records.toList();
    final aiRecords = all.where((record) => record.isVersusAi).toList();

    var shots = 0;
    var potted = 0;
    var bestShotPotted = 0;
    var bestStreak = 0;
    for (final record in all) {
      shots += record.shots.length;
      var streak = 0;
      int? lastPlayer;
      for (final shot in record.shots) {
        final count = shot.potted.where((id) => id != 0).length;
        potted += count;
        if (count > bestShotPotted) bestShotPotted = count;
        if (count > 0 && shot.player == lastPlayer) {
          streak++;
        } else if (count > 0) {
          streak = 1;
        } else {
          streak = 0;
        }
        lastPlayer = shot.player;
        if (streak > bestStreak) bestStreak = streak;
      }
    }

    final byLabel = <String, ({int matches, int wins})>{};
    for (final record in aiRecords) {
      final current = byLabel[record.difficultyLabel];
      byLabel[record.difficultyLabel] = (
        matches: (current?.matches ?? 0) + 1,
        wins: (current?.wins ?? 0) + (record.playerWin ? 1 : 0),
      );
    }
    const knownLabels = ['入门', '进阶', '高手'];
    final labels = [
      ...knownLabels.where(byLabel.containsKey),
      ...byLabel.keys.where((label) => !knownLabels.contains(label)),
    ];
    final difficulties = [
      for (final label in labels)
        DifficultyStats(
          label: label,
          matches: byLabel[label]!.matches,
          wins: byLabel[label]!.wins,
        ),
    ];

    return MatchStats(
      matches: all.length,
      aiMatches: aiRecords.length,
      aiWins: aiRecords.where((record) => record.playerWin).length,
      twoPlayerMatches: all.where((record) => record.isTwoPlayers).length,
      shots: shots,
      potted: potted,
      bestShotPotted: bestShotPotted,
      bestStreak: bestStreak,
      difficulties: difficulties,
      recentAiResults: [
        for (final record in aiRecords.take(5)) record.playerWin,
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

  bool get isEmpty => matches == 0;

  int get aiLosses => aiMatches - aiWins;

  double get aiWinRate => aiMatches == 0 ? 0 : aiWins / aiMatches;

  double get averageShots => matches == 0 ? 0 : shots / matches;

  /// 进球率：每杆平均打进的目标球数（0~1 之间不保证，可能一杆多球）。
  double get potRate => shots == 0 ? 0 : potted / shots;
}
