import 'package:chinese_eight_ball/core/match_trend.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/record_factory.dart';

void main() {
  test('没有对局时补齐 7 天且每天为空', () {
    final trend = DailyTrend.of(const [], now: DateTime(2026, 11, 7, 23));

    expect(trend.points, hasLength(7));
    expect(trend.points.first.date, DateTime(2026, 11));
    expect(trend.points.last.date, DateTime(2026, 11, 7));
    expect(trend.points.where((point) => !point.isEmpty), isEmpty);
    expect(trend.matches, 0);
  });

  test('按天聚合场次与进球，窗口外与母球不计入', () {
    final trend = DailyTrend.of([
      testRecord(
        index: 0,
        createdAt: DateTime(2026, 11, 4, 10),
        shots: [
          (0, [1, 2]),
        ],
      ),
      testRecord(
        index: 1,
        createdAt: DateTime(2026, 11, 4, 22),
        shots: [
          (0, [3]),
        ],
      ),
      testRecord(
        index: 2,
        createdAt: DateTime(2026, 11, 7, 9),
        shots: [
          (0, [0, 4]),
        ],
      ),
      testRecord(index: 3, createdAt: DateTime(2026, 10, 30, 9)),
    ], now: DateTime(2026, 11, 7, 23));

    final nov4 = trend.points[3];
    expect(nov4.matches, 2);
    expect(nov4.shots, 2);
    expect(nov4.potted, 3);
    expect(nov4.potRate, closeTo(1.5, 1e-9));
    expect(trend.points[4].isEmpty, isTrue);
    expect(trend.points.last.matches, 1);
    expect(trend.points.last.potted, 1);
    expect(trend.matches, 3);
  });

  test('可限制天数并按日期从旧到新排列', () {
    final trend = DailyTrend.of(
      [
        testRecord(index: 0, createdAt: DateTime(2026, 11, 7, 9)),
        testRecord(index: 1, createdAt: DateTime(2026, 11, 6, 9)),
      ],
      days: 3,
      now: DateTime(2026, 11, 7, 23),
    );

    expect(
      [for (final point in trend.points) point.date],
      [DateTime(2026, 11, 5), DateTime(2026, 11, 6), DateTime(2026, 11, 7)],
    );
    expect(trend.matches, 2);
  });
}
