import 'package:chinese_eight_ball/core/match_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/record_factory.dart';

void main() {
  test('空记录返回零值', () {
    final stats = MatchStats.fromRecords(const []);
    expect(stats.isEmpty, isTrue);
    expect(stats.matches, 0);
    expect(stats.aiWinRate, 0);
    expect(stats.averageShots, 0);
    expect(stats.potRate, 0);
    expect(stats.difficulties, isEmpty);
    expect(stats.recentAiResults, isEmpty);
  });

  test('汇总场次、胜率、杆数与进球', () {
    final stats = MatchStats.fromRecords([
      testRecord(
        index: 0,
        difficulty: '入门',
        shots: [
          (0, [1]),
          (0, [2, 3]),
        ],
      ),
      testRecord(index: 1, win: false, difficulty: '高手'),
      testRecord(
        index: 2,
        mode: 'twoPlayers',
        shots: [
          (1, [9]),
        ],
      ),
    ]);

    expect(stats.matches, 3);
    expect(stats.aiMatches, 2);
    expect(stats.aiWins, 1);
    expect(stats.aiLosses, 1);
    expect(stats.aiWinRate, closeTo(0.5, 1e-9));
    expect(stats.twoPlayerMatches, 1);
    expect(stats.shots, 4);
    expect(stats.potted, 4);
    expect(stats.bestShotPotted, 2);
    expect(stats.averageShots, closeTo(4 / 3, 1e-9));
    expect(stats.potRate, closeTo(1, 1e-9));
  });

  test('连续进球按球手切换重新计数', () {
    final stats = MatchStats.fromRecords([
      testRecord(
        index: 0,
        shots: [
          (0, [1]),
          (0, [2]),
          (1, [9]),
          (1, [10]),
          (1, [11]),
          (0, [3]),
        ],
      ),
    ]);
    expect(stats.bestShotPotted, 1);
    expect(stats.bestStreak, 3);
  });

  test('难度分组只统计人机对局', () {
    final stats = MatchStats.fromRecords([
      testRecord(index: 0, difficulty: '入门'),
      testRecord(index: 1, win: false, difficulty: '入门'),
      testRecord(index: 2, difficulty: '高手'),
      testRecord(index: 3, mode: 'twoPlayers', difficulty: '高手'),
    ]);

    expect(stats.difficulties.length, 2);
    final easy = stats.difficulties.firstWhere((item) => item.label == '入门');
    final hard = stats.difficulties.firstWhere((item) => item.label == '高手');
    expect(easy.matches, 2);
    expect(easy.wins, 1);
    expect(easy.winRate, closeTo(0.5, 1e-9));
    expect(hard.matches, 1);
    expect(hard.wins, 1);
  });

  test('最近战绩最多保留 5 场且保持从新到旧', () {
    final stats = MatchStats.fromRecords([
      for (var i = 0; i < 7; i++) testRecord(index: i, win: i.isEven),
    ]);
    expect(stats.recentAiResults, [true, false, true, false, true]);
  });

  test('输入乱序时仍按时间取最近的战绩', () {
    final stats = MatchStats.fromRecords([
      testRecord(index: 2),
      testRecord(index: 0),
      testRecord(index: 5),
      testRecord(index: 1, win: false),
      testRecord(index: 4, win: false),
      testRecord(index: 3, win: false),
    ]);
    // 最新 5 场：5(胜) 4(负) 3(负) 2(胜) 1(负)
    expect(stats.recentAiResults, [true, false, false, true, false]);
  });

  test('难度未知时追加在已知难度之后', () {
    final difficulties = DifficultyStats.breakdown([
      testRecord(index: 0, difficulty: '高手'),
      testRecord(index: 1, difficulty: '自定义'),
      testRecord(index: 2, difficulty: '入门'),
    ]);
    expect([for (final item in difficulties) item.label], ['入门', '高手', '自定义']);
  });

  test('母球落袋不计入进球数', () {
    final stats = MatchStats.fromRecords([
      testRecord(
        index: 0,
        shots: [
          (0, [0, 1]),
          (0, [0]),
        ],
      ),
    ]);
    expect(stats.potted, 1);
    expect(stats.bestShotPotted, 1);
    expect(stats.potRate, closeTo(0.5, 1e-9));
  });

  test('走势最多 8 场并按时间从旧到新', () {
    final stats = MatchStats.fromRecords([
      for (var i = 0; i < 10; i++)
        testRecord(
          index: i,
          mode: i == 9 ? 'twoPlayers' : 'vsAi',
          win: i.isEven,
          shots: [
            (0, i == 3 ? [1, 2] : [1]),
            (1, const []),
          ],
        ),
    ]);

    final points = stats.trend.points;
    expect(points, hasLength(8));
    expect(points.first.createdAt, DateTime(2026, 11, 5, 20, 2));
    expect(points.last.createdAt, DateTime(2026, 11, 5, 20, 9));
    expect(points[0].win, isTrue);
    expect(points.last.win, isNull);
    expect(points[1].potted, 2);
    expect(points[1].potRate, closeTo(1, 1e-9));
  });

  test('统计包含按基准时间聚合的近 7 天活动', () {
    final stats = MatchStats.fromRecords([
      testRecord(index: 0),
      testRecord(index: 1, createdAt: DateTime(2026, 11, 4, 20)),
    ], now: DateTime(2026, 11, 5, 23));

    expect(stats.daily.points, hasLength(7));
    expect(stats.daily.points.last.date, DateTime(2026, 11, 5));
    expect(stats.daily.points.last.matches, 1);
    expect(stats.daily.points[5].matches, 1);
  });
}
