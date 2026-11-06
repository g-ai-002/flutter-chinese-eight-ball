import 'package:chinese_eight_ball/core/match_record.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';

/// 构造统计与回放用例所需的对局记录，按 [index] 分钟递增时间。
MatchRecord testRecord({
  required int index,
  DateTime? createdAt,
  String mode = 'vsAi',
  bool win = true,
  String difficulty = '进阶',
  List<(int player, List<int> potted)> shots = const [(0, [])],
}) {
  final balls = TableGeometry.rackBalls();
  final cue = balls.firstWhere((ball) => ball.isCue);
  return MatchRecord(
    id: 'record-$index',
    createdAt:
        createdAt ?? DateTime(2026, 11, 5, 20).add(Duration(minutes: index)),
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
