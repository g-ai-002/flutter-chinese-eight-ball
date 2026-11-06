import 'dart:math' as math;

import 'ball.dart';
import 'physics.dart';
import 'rules.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// AI 难度：候选数量、瞄准误差与力度误差依次收紧。
enum AiDifficulty {
  easy('入门', 4, 0.05, 0.16),
  normal('进阶', 8, 0.016, 0.07),
  hard('高手', 14, 0.005, 0.025);

  const AiDifficulty(
    this.label,
    this.candidateLimit,
    this.aimError,
    this.powerError,
  );

  final String label;
  final int candidateLimit;
  final double aimError;
  final double powerError;

  static AiDifficulty byName(String? name) =>
      values.firstWhere((value) => value.name == name, orElse: () => normal);
}

class AiShot {
  const AiShot({
    required this.angle,
    required this.power,
    required this.score,
    this.targetBallId,
    this.pocketIndex,
    this.isSafety = false,
  });

  final double angle;
  final double power;
  final double score;
  final int? targetBallId;
  final int? pocketIndex;

  /// 本杆是否为防守杆，用于日志与界面提示。
  final bool isSafety;
}

class _Candidate {
  const _Candidate({
    required this.angle,
    required this.geometryScore,
    required this.targetBallId,
    required this.pocketIndex,
  });

  final double angle;
  final double geometryScore;
  final int targetBallId;
  final int pocketIndex;
}

/// 中式黑八 AI：按「目标球 → 袋口」枚举进球线路，过滤阻挡后
/// 用真实物理逐杆试算，按进球、犯规与母球走位综合打分。
class EightBallAi {
  EightBallAi({math.Random? random}) : _random = random ?? math.Random();

  static const List<double> _powerLevels = [0.42, 0.62, 0.85];

  /// 防守杆的力度档位：只求轻碰与藏球，不追求走位距离。
  static const List<double> _safetyPowers = [0.24, 0.36, 0.52];

  /// 切球角过小说明几乎擦边，直接放弃这条线路。
  static const double _minCut = 0.16;

  /// 幽灵球额外外移，避免目标球与袋口方向完全共线。
  static const double _ghostClearance = 0.0012;

  static const double _scratchPenalty = 260;
  static const double _ownPotBonus = 150;
  static const double _opponentPotPenalty = 90;
  static const double _eightWinBonus = 5000;
  static const double _eightLossPenalty = 5000;
  static const double _noContactPenalty = 420;
  static const double _wrongGroupPenalty = 320;
  static const double _eightContactPenalty = 380;
  static const double _positionBaseBonus = 40;
  static const double _positionLineScale = 12;
  static const double _positionDistanceScale = 18;
  static const double _railPenalty = 25;
  static const double _pocketPenalty = 26;
  static const double _railMargin = 0.06;

  /// 进攻得分低于该值时，AI 会同时评估防守杆，避免硬打送机会。
  static const double _attackConfidence = 90;
  static const double _safetyGainMargin = 10;
  static const double _safetyBase = 55;
  static const double _safetyScratchPenalty = 240;
  static const double _safetyWrongContactPenalty = 150;
  static const double _safetyEightPotPenalty = 4000;
  static const double _safetyEightContactPenalty = 110;
  static const double _safetyOpponentPotPenalty = 80;
  static const double _safetyRailBonus = 20;
  static const double _safetyDistanceScale = 16;
  static const double _safetyThreatPenalty = 8;
  static const double _safetyHiddenBonus = 12;
  static const double _safetyTargetRailBonus = 6;

  final math.Random _random;

  AiShot decide({
    required List<BallState> balls,
    required PlayerGroup? group,
    required bool onEight,
    AiDifficulty difficulty = AiDifficulty.normal,
  }) {
    final cue = balls.firstWhere((ball) => ball.isCue);
    final targets = _legalTargets(balls, group, onEight);

    if (!cue.active || targets.isEmpty) {
      return AiShot(
        angle: _random.nextDouble() * math.pi * 2,
        power: 0.5,
        score: 0,
      );
    }

    final candidates = _attackCandidates(cue.position, targets, balls)
      ..sort((a, b) => b.geometryScore.compareTo(a.geometryScore));
    final limited = candidates.take(difficulty.candidateLimit);

    final attack = _bestEvaluatedShot(
      candidates: limited,
      balls: balls,
      group: group,
      onEight: onEight,
    );
    // 只有进攻把握不足时才试算防守，避免每次都多跑一轮物理模拟。
    var chosen = attack;
    if (attack == null || attack.score < _attackConfidence) {
      final safety = _bestSafetyShot(
        balls: balls,
        targets: targets,
        group: group,
        onEight: onEight,
      );
      chosen = _preferShot(attack, safety);
    }
    chosen ??= _safetyShot(balls, targets);
    return AiShot(
      angle: _applyError(chosen.angle, difficulty.aimError),
      power: (chosen.power + _symmetric(difficulty.powerError)).clamp(
        0.15,
        1.0,
      ),
      score: chosen.score,
      targetBallId: chosen.targetBallId,
      pocketIndex: chosen.pocketIndex,
      isSafety: chosen.isSafety,
    );
  }

  /// 进攻把握不足且防守收益明显更高时选择防守。
  AiShot? _preferShot(AiShot? attack, AiShot? safety) {
    if (attack == null) return safety;
    if (safety == null) return attack;
    if (safety.score > attack.score + _safetyGainMargin) return safety;
    return attack;
  }

  /// 枚举所有「目标球 → 袋口」组合，只保留几何上可行的线路。
  List<_Candidate> _attackCandidates(
    Vec2 cue,
    List<BallState> targets,
    List<BallState> balls,
  ) {
    final candidates = <_Candidate>[];
    for (final target in targets) {
      for (
        var pocketIndex = 0;
        pocketIndex < TableGeometry.pockets.length;
        pocketIndex++
      ) {
        final candidate = _candidateFor(
          cue: cue,
          target: target,
          pocketIndex: pocketIndex,
          balls: balls,
        );
        if (candidate != null) candidates.add(candidate);
      }
    }
    return candidates;
  }

  _Candidate? _candidateFor({
    required Vec2 cue,
    required BallState target,
    required int pocketIndex,
    required List<BallState> balls,
  }) {
    final line = _lineGeometry(cue, target, pocketIndex, balls);
    if (line == null) return null;
    return _Candidate(
      angle: line.angle,
      geometryScore: line.score,
      targetBallId: target.id,
      pocketIndex: pocketIndex,
    );
  }

  /// 评估母球 → 目标球 → 指定袋口的线路；不可行返回 null。
  ///
  /// 进攻候选与走位评分共用同一套几何判定，保证「AI 认为的好位」与
  /// 它实际会选择的线路一致。
  ({double angle, double score})? _lineGeometry(
    Vec2 cue,
    BallState target,
    int pocketIndex,
    List<BallState> balls,
  ) {
    final pocket = TableGeometry.pockets[pocketIndex];
    final pocketDirection = (pocket - target.position).normalized;
    if (pocketDirection.lengthSquared < 0.5) return null;

    final ghost =
        target.position -
        pocketDirection * (TableGeometry.ballRadius * 2 + _ghostClearance);
    if (ghost.x < 0 ||
        ghost.x > TableGeometry.width ||
        ghost.y < 0 ||
        ghost.y > TableGeometry.height) {
      return null;
    }

    final cut = directionOf(angleOf(cue, ghost)).dot(pocketDirection);
    if (cut < _minCut) return null;
    if (_pathBlocked(
      from: cue,
      to: ghost,
      balls: balls,
      ignore: {0, target.id},
    )) {
      return null;
    }
    if (_pathBlocked(
      from: target.position,
      to: pocket,
      balls: balls,
      ignore: {target.id},
    )) {
      return null;
    }

    final distance = cue.distanceTo(target.position);
    return (angle: angleOf(cue, ghost), score: cut * 3.6 - distance * 0.35);
  }

  AiShot? _bestEvaluatedShot({
    required Iterable<_Candidate> candidates,
    required List<BallState> balls,
    required PlayerGroup? group,
    required bool onEight,
  }) {
    AiShot? best;
    for (final candidate in candidates) {
      for (final power in _powerLevels) {
        final shot = _evaluate(
          balls: balls,
          angle: candidate.angle,
          power: power,
          group: group,
          onEight: onEight,
          targetBallId: candidate.targetBallId,
          pocketIndex: candidate.pocketIndex,
        );
        if (best == null || shot.score > best.score) best = shot;
      }
    }
    return best;
  }

  List<BallState> _legalTargets(
    List<BallState> balls,
    PlayerGroup? group,
    bool onEight,
  ) {
    final active = [
      for (final ball in balls)
        if (ball.active && !ball.isCue) ball,
    ];
    if (onEight) {
      return [
        for (final ball in active)
          if (ball.isEight) ball,
      ];
    }
    if (group == null) {
      return [
        for (final ball in active)
          if (!ball.isEight) ball,
      ];
    }
    final own = [
      for (final ball in active)
        if (ball.kind == group.kind) ball,
    ];
    if (own.isNotEmpty) return own;
    return [
      for (final ball in active)
        if (ball.isEight) ball,
    ];
  }

  AiShot _evaluate({
    required List<BallState> balls,
    required double angle,
    required double power,
    required PlayerGroup? group,
    required bool onEight,
    required int targetBallId,
    required int pocketIndex,
  }) {
    final simulation = ShotSimulation(balls: balls);
    simulation.strike(angle, power);
    final outcome = simulation.simulateToRest(limit: 9);

    var score = _pottedScore(outcome, group, onEight, pocketIndex);
    score += _contactScore(outcome, group, onEight);
    score += _cuePositionScore(simulation, group);

    return AiShot(
      angle: angle,
      power: power,
      score: score,
      targetBallId: targetBallId,
      pocketIndex: pocketIndex,
    );
  }

  double _pottedScore(
    ShotOutcome outcome,
    PlayerGroup? group,
    bool onEight,
    int targetPocket,
  ) {
    var score = 0.0;
    for (final event in outcome.potted) {
      final id = event.ballId;
      if (id == 0) {
        score -= _scratchPenalty;
      } else if (id == 8) {
        // 指袋规则下，只有落进候选袋口才算赢。
        final pocketMatched = outcome.pocketOf(8) == targetPocket;
        score += onEight && pocketMatched ? _eightWinBonus : -_eightLossPenalty;
      } else if (group == null || MatchRules.kindOfBall(id) == group.kind) {
        score += _ownPotBonus;
      } else {
        score -= _opponentPotPenalty;
      }
    }
    return score;
  }

  double _contactScore(ShotOutcome outcome, PlayerGroup? group, bool onEight) {
    if (outcome.firstContact == null) return -_noContactPenalty;
    if (onEight) return 0;

    final kind = MatchRules.kindOfBall(outcome.firstContact!);
    final expected = group?.kind;
    var score = 0.0;
    if (expected != null && kind != expected) score -= _wrongGroupPenalty;
    if (kind == BallKind.eight) score -= _eightContactPenalty;
    return score;
  }

  /// 母球停位评分：按下一杆最优线路（切角、距离、袋口与阻挡）衡量走位，
  /// 同时规避贴库与袋口边缘，而不是只看离最近一颗球多远。
  double _cuePositionScore(ShotSimulation simulation, PlayerGroup? group) {
    final cue = simulation.cueBall;
    if (!cue.active) return 0;

    var score = 0.0;
    final remaining = [
      for (final ball in simulation.balls)
        if (ball.active &&
            !ball.isCue &&
            !ball.isEight &&
            (group == null || ball.kind == group.kind))
          ball,
    ];
    var bestNext = double.negativeInfinity;
    for (final ball in remaining) {
      for (
        var pocketIndex = 0;
        pocketIndex < TableGeometry.pockets.length;
        pocketIndex++
      ) {
        final line = _lineGeometry(
          cue.position,
          ball,
          pocketIndex,
          simulation.balls,
        );
        if (line != null && line.score > bestNext) bestNext = line.score;
      }
    }
    if (bestNext.isFinite) {
      score += _positionBaseBonus + bestNext * _positionLineScale;
    } else if (remaining.isNotEmpty) {
      var nearest = double.infinity;
      for (final ball in remaining) {
        final distance = cue.position.distanceTo(ball.position);
        if (distance < nearest) nearest = distance;
      }
      score +=
          _positionBaseBonus * 0.5 -
          math.min(nearest, 1.6) * _positionDistanceScale;
    }

    final edge = _edgeDistance(cue.position);
    if (edge < _railMargin) score -= _railPenalty;
    if (edge < TableGeometry.ballRadius * 1.2) score -= _railPenalty * 0.6;
    if (_pocketDistance(cue.position) < TableGeometry.pocketRadius * 1.6) {
      score -= _pocketPenalty;
    }
    return score;
  }

  /// 枚举防守线路：轻碰合法目标球，把母球留在远离对手、贴库或被遮挡的位置。
  AiShot? _bestSafetyShot({
    required List<BallState> balls,
    required List<BallState> targets,
    required PlayerGroup? group,
    required bool onEight,
  }) {
    final cue = balls.firstWhere((ball) => ball.isCue);
    AiShot? best;
    for (final target in targets) {
      for (final angle in _safetyAngles(cue.position, target)) {
        for (final power in _safetyPowers) {
          final simulation = ShotSimulation(balls: balls);
          simulation.strike(angle, power);
          final outcome = simulation.simulateToRest(limit: 8);
          final score = _safetyScore(
            outcome: outcome,
            simulation: simulation,
            group: group,
            onEight: onEight,
          );
          if (score < 0) continue;
          if (best == null || score > best.score) {
            best = AiShot(
              angle: angle,
              power: power,
              score: score,
              targetBallId: target.id,
              isSafety: true,
            );
          }
        }
      }
    }
    return best;
  }

  /// 正碰与薄碰各一条线路，薄碰更容易把母球留在库边。
  Iterable<double> _safetyAngles(Vec2 cue, BallState target) sync* {
    final direction = (target.position - cue).normalized;
    if (direction.lengthSquared < 0.5) return;
    yield angleOf(cue, target.position);
    final ghost =
        target.position +
        direction.perpendicular * (TableGeometry.ballRadius * 0.9);
    yield angleOf(cue, ghost);
  }

  /// 防守杆评分：先保证合法接触，再比较母球安全度与对手下一杆威胁。
  double _safetyScore({
    required ShotOutcome outcome,
    required ShotSimulation simulation,
    required PlayerGroup? group,
    required bool onEight,
  }) {
    final firstContact = outcome.firstContact;
    if (firstContact == null) return -1;

    var score = _safetyBase;
    final firstKind = MatchRules.kindOfBall(firstContact);
    final expected = group?.kind;
    if (outcome.cuePotted) score -= _safetyScratchPenalty;
    if (outcome.eightPotted) score -= _safetyEightPotPenalty;
    if (onEight) {
      if (firstKind != BallKind.eight) score -= _safetyWrongContactPenalty;
    } else {
      if (expected != null && firstKind != expected) {
        score -= _safetyWrongContactPenalty;
      }
      if (firstKind == BallKind.eight) score -= _safetyEightContactPenalty;
    }

    for (final event in outcome.potted) {
      final id = event.ballId;
      if (id == 0 || id == 8) continue;
      if (group != null && MatchRules.kindOfBall(id) == group.kind) {
        score += _ownPotBonus * 0.5;
      } else {
        score -= _safetyOpponentPotPenalty;
      }
    }
    // 把目标球推向库边，对手下一杆的进球角度会更差。
    for (final ball in simulation.balls) {
      if (ball.id == firstContact &&
          ball.active &&
          _edgeDistance(ball.position) < _railMargin) {
        score += _safetyTargetRailBonus;
      }
    }

    final cue = simulation.cueBall;
    if (!cue.active) return score;
    final edge = _edgeDistance(cue.position);
    if (edge < _railMargin) score += _safetyRailBonus;
    if (edge < TableGeometry.ballRadius * 1.2) score += _safetyRailBonus * 0.5;

    final opponents = _opponentTargets(simulation.balls, group);
    if (opponents.isEmpty) return score;
    var nearest = double.infinity;
    for (final ball in opponents) {
      final distance = cue.position.distanceTo(ball.position);
      if (distance < nearest) nearest = distance;
    }
    score += math.min(nearest, 2.4) * _safetyDistanceScale;
    score -=
        _opponentThreat(cue.position, opponents, simulation.balls) *
        _safetyThreatPenalty;
    score +=
        _hiddenTargets(cue.position, opponents, simulation.balls) *
        _safetyHiddenBonus;
    return score;
  }

  /// 对手下一杆的最佳线路分；越低越安全。
  double _opponentThreat(
    Vec2 cue,
    List<BallState> targets,
    List<BallState> balls,
  ) {
    var best = 0.0;
    for (final target in targets) {
      for (
        var pocketIndex = 0;
        pocketIndex < TableGeometry.pockets.length;
        pocketIndex++
      ) {
        final line = _lineGeometry(cue, target, pocketIndex, balls);
        if (line != null && line.score > best) best = line.score;
      }
    }
    return best;
  }

  /// 母球到对手目标球被完全遮挡的数量，用于给「藏球」加分。
  int _hiddenTargets(Vec2 cue, List<BallState> targets, List<BallState> balls) {
    var hidden = 0;
    for (final target in targets) {
      if (_pathBlocked(
        from: cue,
        to: target.position,
        balls: balls,
        ignore: {0, target.id},
      )) {
        hidden++;
      }
    }
    return hidden;
  }

  List<BallState> _opponentTargets(List<BallState> balls, PlayerGroup? group) {
    if (group == null) {
      return [
        for (final ball in balls)
          if (ball.active && !ball.isCue && !ball.isEight) ball,
      ];
    }
    final kind = group == PlayerGroup.solids ? BallKind.stripe : BallKind.solid;
    final own = [
      for (final ball in balls)
        if (ball.active && !ball.isCue && ball.kind == kind) ball,
    ];
    if (own.isNotEmpty) return own;
    return [
      for (final ball in balls)
        if (ball.active && ball.isEight) ball,
    ];
  }

  /// 完全找不到防守线路时的兜底：轻碰最近合法球，避免空杆犯规。
  AiShot _safetyShot(List<BallState> balls, List<BallState> targets) {
    final cue = balls.firstWhere((ball) => ball.isCue);
    final target = targets.reduce(
      (best, ball) =>
          cue.position.distanceTo(ball.position) <
              cue.position.distanceTo(best.position)
          ? ball
          : best,
    );
    return AiShot(
      angle: angleOf(cue.position, target.position),
      power: 0.4,
      score: -100,
      targetBallId: target.id,
      isSafety: true,
    );
  }

  double _edgeDistance(Vec2 point) => math.min(
    math.min(point.x, TableGeometry.width - point.x),
    math.min(point.y, TableGeometry.height - point.y),
  );

  double _pocketDistance(Vec2 point) {
    var nearest = double.infinity;
    for (final pocket in TableGeometry.pockets) {
      final distance = point.distanceTo(pocket);
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  bool _pathBlocked({
    required Vec2 from,
    required Vec2 to,
    required List<BallState> balls,
    required Set<int> ignore,
  }) {
    const clearance = TableGeometry.ballRadius * 2 - 0.002;
    for (final ball in balls) {
      if (!ball.active || ignore.contains(ball.id)) continue;
      if (distanceToSegment(ball.position, from, to) < clearance) return true;
    }
    return false;
  }

  double _applyError(double angle, double error) => angle + _symmetric(error);

  double _symmetric(double magnitude) =>
      (_random.nextDouble() * 2 - 1) * magnitude;
}
