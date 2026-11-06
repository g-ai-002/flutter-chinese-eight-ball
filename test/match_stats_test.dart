import 'package:chinese_eight_ball/core/match_record.dart';
import 'package:chinese_eight_ball/core/match_stats.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

MatchRecord record({
  required int index,
  String mode = 'vsAi',
  bool win = true,
  String difficulty = '进阶',
  List<(int player, List<int> potted)> shots = const [(0, [])],
}) {
  final balls = TableGeometry.rackBalls();
  final cue = balls.firstWhere((ball) => ball.isCue);
  return MatchRecord(
    id: 'stats-$index',
    createdAt: DateTime(2026, 11, 5, 20).add(Duration(minutes: index)),
    mode: mode,
    modeLabel: mode == 'vsAi' ? '人机对战' : '双人对战',
    difficultyLabel: difficulty,
    humanSide: 0,
    winner: win ? 0 : 1,
    winnerName: win ? '玩家' : '电脑',
    title: win ? '你赢了' : '电脑获胜',
    playerWin: win,
    endReason: '清台后打进黑八',
    shots: [
      for (final (player, potted) in shots)
        ReplayShot(
          player: player,
          balls: balls,
          angle: angleOf(cue.position, TableGeometry.footSpot),
          power: 0.8,
          calledPocket: null,
          result: '进球',
          potted: potted,
        ),
    ],
  );
}

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
      record(
        index: 0,
        difficulty: '入门',
        shots: [
          (0, [1]),
          (0, [2, 3]),
        ],
      ),
      record(index: 1, win: false, difficulty: '高手'),
      record(
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
      record(
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
      record(index: 0, difficulty: '入门'),
      record(index: 1, win: false, difficulty: '入门'),
      record(index: 2, difficulty: '高手'),
      record(index: 3, mode: 'twoPlayers', difficulty: '高手'),
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
      for (var i = 0; i < 7; i++) record(index: i, win: i.isEven),
    ]);
    expect(stats.recentAiResults, [true, false, true, false, true]);
  });

  test('母球落袋不计入进球数', () {
    final stats = MatchStats.fromRecords([
      record(
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
}
