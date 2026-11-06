import 'match_record.dart';

/// 逐杆进球统计：累计杆数、进球数、单杆最多进球与最长连续进球。
///
/// 母球（0 号）不计入进球；连续进球按同一球手的连续进球杆数计算，
/// 换人或空杆都会中断，且不跨对局累加。
class ShotTally {
  const ShotTally({
    required this.shots,
    required this.potted,
    required this.bestShotPotted,
    required this.bestStreak,
  });

  factory ShotTally.of(Iterable<MatchRecord> records) {
    var shots = 0;
    var potted = 0;
    var bestShotPotted = 0;
    var bestStreak = 0;
    for (final record in records) {
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
    return ShotTally(
      shots: shots,
      potted: potted,
      bestShotPotted: bestShotPotted,
      bestStreak: bestStreak,
    );
  }

  final int shots;
  final int potted;

  /// 单杆最多进球数与单场最长连续进球杆数。
  final int bestShotPotted;
  final int bestStreak;
}
