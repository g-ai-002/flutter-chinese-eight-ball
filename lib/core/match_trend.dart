import 'match_record.dart';
import 'shot_tally.dart';

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

  double get potRate => potRateOf(shots, potted);
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
          shots: record.shotCount,
          potted: record.pottedTargets,
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
    return potRateOf(shots, potted);
  }
}

/// 单日对局聚合：当天场次与进球表现。
class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.matches,
    required this.shots,
    required this.potted,
  });

  final DateTime date;
  final int matches;
  final int shots;
  final int potted;

  bool get isEmpty => matches == 0;

  double get potRate => potRateOf(shots, potted);
}

/// 近 [days] 天的对局活动：按日期从旧到新排列，没有对局的日期补零，
/// 供统计页绘制每日柱状图；只读取本机记录，不修改任何数据。
class DailyTrend {
  const DailyTrend(this.points);

  factory DailyTrend.of(
    Iterable<MatchRecord> records, {
    int days = 7,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final byDay = <DateTime, List<MatchRecord>>{};
    for (final record in records) {
      (byDay[_dateOnly(record.createdAt)] ??= []).add(record);
    }
    return DailyTrend([
      for (var i = days - 1; i >= 0; i--)
        _dayPoint(DateTime(today.year, today.month, today.day - i), byDay),
    ]);
  }

  final List<DailyPoint> points;

  int get matches => points.fold(0, (sum, point) => sum + point.matches);
}

DailyPoint _dayPoint(DateTime date, Map<DateTime, List<MatchRecord>> byDay) {
  final day = byDay[date] ?? const <MatchRecord>[];
  return DailyPoint(
    date: date,
    matches: day.length,
    shots: day.fold(0, (sum, record) => sum + record.shotCount),
    potted: day.fold(0, (sum, record) => sum + record.pottedTargets),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
