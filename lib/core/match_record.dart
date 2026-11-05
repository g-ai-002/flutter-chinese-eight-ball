import 'dart:convert';
import 'dart:math' as math;

import 'ball.dart';
import 'vec.dart';

/// 回放中的一杆：出杆前的完整球局、击球参数与裁定结果。
class ReplayShot {
  ReplayShot({
    required this.player,
    required this.balls,
    required this.angle,
    required this.power,
    required this.calledPocket,
    required this.result,
    required this.potted,
  });

  final int player;

  /// 出杆前的台面状态，回放按此重演物理，避免误差逐杆累积。
  final List<BallState> balls;
  final double angle;
  final double power;
  final int? calledPocket;
  final String result;
  final List<int> potted;

  Map<String, Object?> toJson() => {
    'p': player,
    'a': _round(angle, 4),
    'w': _round(power, 3),
    if (calledPocket != null) 'k': calledPocket,
    'r': result,
    if (potted.isNotEmpty) 'o': potted,
    'b': [
      for (final ball in balls)
        if (ball.active)
          [ball.id, _round(ball.position.x, 4), _round(ball.position.y, 4)],
    ],
  };

  static ReplayShot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final layout = raw['b'];
    if (layout is! List) return null;
    final balls = <BallState>[];
    for (final item in layout) {
      if (item is! List || item.length < 3) continue;
      final id = _asInt(item[0]);
      final x = _asDouble(item[1]);
      final y = _asDouble(item[2]);
      if (id == null || x == null || y == null) continue;
      balls.add(BallState(spec: BallSpec.fromId(id), position: Vec2(x, y)));
    }
    if (balls.isEmpty || !balls.any((ball) => ball.isCue)) return null;

    final potted = <int>[];
    final rawPotted = raw['o'];
    if (rawPotted is List) {
      for (final id in rawPotted) {
        final value = _asInt(id);
        if (value != null) potted.add(value);
      }
    }
    return ReplayShot(
      player: _asInt(raw['p']) ?? 0,
      balls: balls,
      angle: _asDouble(raw['a']) ?? 0,
      power: (_asDouble(raw['w']) ?? 0.5).clamp(0.05, 1.0),
      calledPocket: _asInt(raw['k']),
      result: raw['r'] is String ? raw['r'] as String : '',
      potted: potted,
    );
  }
}

/// 一场已完成的对局：结果、参数与逐杆记录。
class MatchRecord {
  MatchRecord({
    required this.id,
    required this.createdAt,
    required this.mode,
    required this.modeLabel,
    required this.difficultyLabel,
    required this.humanSide,
    required this.winner,
    required this.winnerName,
    required this.title,
    required this.playerWin,
    required this.endReason,
    required this.shots,
  });

  final String id;
  final DateTime createdAt;

  /// [MatchController] 中 [GameMode] 的名称，用于回放时推断球手称呼。
  final String mode;
  final String modeLabel;
  final String difficultyLabel;
  final int humanSide;
  final int winner;
  final String winnerName;

  /// 终局弹窗标题，如「你赢了」「玩家二获胜」。
  final String title;
  final bool playerWin;
  final String endReason;
  final List<ReplayShot> shots;

  int get shotCount => shots.length;

  bool get isVersusAi => mode == 'vsAi';

  bool get isTwoPlayers => mode == 'twoPlayers';

  String playerName(int player) {
    if (isTwoPlayers) return '玩家${player == 0 ? '一' : '二'}';
    if (isVersusAi) return player == humanSide ? '玩家' : '电脑';
    return '练习';
  }

  /// 侧栏与列表用的副标题，例如「人机对战 · 进阶 · 共 12 杆」。
  String get subtitle =>
      '$modeLabel · ${isVersusAi ? difficultyLabel : '同屏轮流'} · 共 $shotCount 杆';

  Map<String, Object?> toJson() => {
    'id': id,
    't': createdAt.toIso8601String(),
    'm': mode,
    'ml': modeLabel,
    'dl': difficultyLabel,
    'hs': humanSide,
    'w': winner,
    'wn': winnerName,
    'ti': title,
    'pw': playerWin,
    'er': endReason,
    's': [for (final shot in shots) shot.toJson()],
  };

  static MatchRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final createdAt = DateTime.tryParse(raw['t'] is String ? raw['t'] as String : '');
    if (createdAt == null) return null;
    final shots = <ReplayShot>[];
    final rawShots = raw['s'];
    if (rawShots is List) {
      for (final item in rawShots) {
        final shot = ReplayShot.fromJson(item);
        if (shot != null) shots.add(shot);
      }
    }
    if (shots.isEmpty) return null;
    return MatchRecord(
      id: raw['id'] is String && (raw['id'] as String).isNotEmpty
          ? raw['id'] as String
          : '${createdAt.millisecondsSinceEpoch}',
      createdAt: createdAt,
      mode: raw['m'] is String ? raw['m'] as String : 'twoPlayers',
      modeLabel: raw['ml'] is String ? raw['ml'] as String : '双人对战',
      difficultyLabel: raw['dl'] is String ? raw['dl'] as String : '进阶',
      humanSide: _asInt(raw['hs']) ?? 0,
      winner: _asInt(raw['w']) ?? 0,
      winnerName: raw['wn'] is String ? raw['wn'] as String : '玩家一',
      title: raw['ti'] is String ? raw['ti'] as String : '对局结束',
      playerWin: raw['pw'] == true,
      endReason: raw['er'] is String ? raw['er'] as String : '本局结束',
      shots: shots,
    );
  }
}

/// 对局记录的本地编码：只保留最近若干场，坏数据整条丢弃。
class MatchHistory {
  MatchHistory._();

  static const int maxRecords = 10;

  static List<MatchRecord> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (parsed is! List) return const [];
    final records = <MatchRecord>[];
    for (final item in parsed) {
      final record = MatchRecord.fromJson(item);
      if (record != null) records.add(record);
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records.take(maxRecords).toList(growable: false);
  }

  static String encode(List<MatchRecord> records) {
    final sorted = [...records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jsonEncode([
      for (final record in sorted.take(maxRecords)) record.toJson(),
    ]);
  }
}

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

double _round(double value, int digits) {
  final factor = math.pow(10, digits).toDouble();
  return (value * factor).round() / factor;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
