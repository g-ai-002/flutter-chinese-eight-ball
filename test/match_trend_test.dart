import 'package:chinese_eight_ball/core/match_trend.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/record_factory.dart';

void main() {
  test('空记录没有走势点且近期进球率为零', () {
    final trend = MatchTrend.of(const []);
    expect(trend.isEmpty, isTrue);
    expect(trend.points, isEmpty);
    expect(trend.recentPotRate, 0);
  });

  test('乱序输入时取最近 8 场并按时间从旧到新排列', () {
    final trend = MatchTrend.of([
      testRecord(index: 5),
      testRecord(index: 1),
      testRecord(index: 9),
      testRecord(index: 3),
      testRecord(index: 0),
      testRecord(index: 8),
      testRecord(index: 2),
      testRecord(index: 7),
      testRecord(index: 6),
      testRecord(index: 4),
    ]);

    expect(trend.points, hasLength(8));
    expect(
      [for (final point in trend.points) point.createdAt],
      [for (var i = 2; i <= 9; i++) DateTime(2026, 11, 5, 20, i)],
    );
  });

  test('近期进球率取最近 3 场且不计母球', () {
    final trend = MatchTrend.of([
      testRecord(
        index: 0,
        shots: [
          (0, [1, 2]),
        ],
      ),
      testRecord(
        index: 1,
        shots: [
          (0, [1]),
        ],
      ),
      testRecord(
        index: 2,
        shots: [
          (0, [0, 3]),
        ],
      ),
      testRecord(index: 3, shots: [(0, [])]),
      testRecord(
        index: 4,
        shots: [
          (0, [1, 2, 3]),
        ],
      ),
    ]);

    // 最近 3 场：1 球 / 1 杆、0 球 / 1 杆、3 球 / 1 杆。
    expect(trend.recentPotRate, closeTo(4 / 3, 1e-9));
    expect(trend.points[2].potted, 1);
  });

  test('双人对局只记录进球走势，不带胜负标记', () {
    final trend = MatchTrend.of([
      testRecord(index: 0, mode: 'twoPlayers'),
      testRecord(index: 1),
    ]);

    expect(trend.points.first.win, isNull);
    expect(trend.points.last.win, isTrue);
  });

  test('可限制走势点数量', () {
    final trend = MatchTrend.of([
      for (var i = 0; i < 5; i++) testRecord(index: i),
    ], limit: 3);

    expect(trend.points, hasLength(3));
    expect(trend.points.first.createdAt, DateTime(2026, 11, 5, 20, 2));
  });
}
