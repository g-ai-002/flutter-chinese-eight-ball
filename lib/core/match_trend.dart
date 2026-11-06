import 'match_record.dart';

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

/// 最近若干场对局走势：按时间从旧到新排列，供统计页图表绘制。
///
/// 输入顺序不限，内部按时间从新到旧取 [limit] 场后反转；进球只统计
/// 目标球（不含母球），与人机胜负一样都来自本机保存的记录。
class MatchTrend {
  const MatchTrend(this.points);

  factory MatchTrend.of(Iterable<MatchRecord> records, {int limit = 8}) {
    final recent = records.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return MatchTrend([
      for (final record in recent.take(limit).toList().reversed)
        TrendPoint(
          createdAt: record.createdAt,
          shots: record.shots.length,
          potted: record.shots.fold(0, (sum, shot) => sum + shot.pottedTargets),
          win: record.isVersusAi ? record.playerWin : null,
        ),
    ]);
  }

  /// 走势点，按时间从旧到新。
  final List<TrendPoint> points;

  bool get isEmpty => points.isEmpty;

  /// 最近 3 场（不足 3 场取全部）的合计进球率，避免单场样本过小导致波动过大。
  double get recentPotRate {
    final recent = points.length <= 3
        ? points
        : points.sublist(points.length - 3);
    final shots = recent.fold(0, (sum, point) => sum + point.shots);
    final potted = recent.fold(0, (sum, point) => sum + point.potted);
    return shots == 0 ? 0 : potted / shots;
  }
}
