import 'ball.dart';
import 'match_record.dart';

/// 对局录制器：随对局收集逐杆记录，终局时生成 [MatchRecord]。
class MatchRecorder {
  MatchRecorder({
    required this.mode,
    required this.modeLabel,
    required this.difficultyLabel,
    required this.humanSide,
  });

  /// 单场最多保留的杆数，避免极端长局拖慢存储与回放。
  static const int maxShots = 240;

  final String mode;
  final String modeLabel;
  final String difficultyLabel;
  final int humanSide;

  final List<ReplayShot> _shots = [];
  _PendingShot? _pending;

  int get shotCount => _shots.length;

  void beginShot({
    required int player,
    required Iterable<BallState> balls,
    required double angle,
    required double power,
    int? calledPocket,
  }) {
    if (_shots.length >= maxShots) {
      _pending = null;
      return;
    }
    _pending = _PendingShot(
      player: player,
      balls: BallState.cloneAll(balls),
      angle: angle,
      power: power,
      calledPocket: calledPocket,
    );
  }

  void endShot({required String result, required Iterable<int> potted}) {
    final pending = _pending;
    _pending = null;
    if (pending == null) return;
    _shots.add(
      ReplayShot(
        player: pending.player,
        balls: pending.balls,
        angle: pending.angle,
        power: pending.power,
        calledPocket: pending.calledPocket,
        result: result,
        potted: potted.toList(growable: false),
      ),
    );
  }

  MatchRecord? finish({
    required int winner,
    required String winnerName,
    required String title,
    required bool playerWin,
    required String reason,
    DateTime? now,
  }) {
    if (_shots.isEmpty) return null;
    final createdAt = now ?? DateTime.now();
    return MatchRecord(
      id: '${createdAt.millisecondsSinceEpoch}',
      createdAt: createdAt,
      mode: mode,
      modeLabel: modeLabel,
      difficultyLabel: difficultyLabel,
      humanSide: humanSide,
      winner: winner,
      winnerName: winnerName,
      title: title,
      playerWin: playerWin,
      endReason: reason,
      shots: List.unmodifiable(_shots),
    );
  }

  void clear() {
    _shots.clear();
    _pending = null;
  }
}

class _PendingShot {
  _PendingShot({
    required this.player,
    required this.balls,
    required this.angle,
    required this.power,
    required this.calledPocket,
  });

  final int player;
  final List<BallState> balls;
  final double angle;
  final double power;
  final int? calledPocket;
}
