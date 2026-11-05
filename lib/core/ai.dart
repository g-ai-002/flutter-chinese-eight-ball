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
  });

  final double angle;
  final double power;
  final double score;
  final int? targetBallId;
  final int? pocketIndex;
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
  static const double _positionDistanceScale = 30;
  static const double _railPenalty = 25;
  static const double _railMargin = 0.06;

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

    final best = _bestEvaluatedShot(
      candidates: limited,
      balls: balls,
      group: group,
      onEight: onEight,
    );
    final chosen = best ?? _safetyShot(balls, targets);
    return AiShot(
      angle: _applyError(chosen.angle, difficulty.aimError),
      power: (chosen.power + _symmetric(difficulty.powerError)).clamp(
        0.15,
        1.0,
      ),
      score: chosen.score,
      targetBallId: chosen.targetBallId,
      pocketIndex: chosen.pocketIndex,
    );
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
    return _Candidate(
      angle: angleOf(cue, ghost),
      geometryScore: cut * 3.6 - distance * 0.35,
      targetBallId: target.id,
      pocketIndex: pocketIndex,
    );
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

  /// 母球停位评分：靠近下一颗目标球加分，贴库减分。
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
    if (remaining.isNotEmpty) {
      var nearest = double.infinity;
      for (final ball in remaining) {
        final distance = cue.position.distanceTo(ball.position);
        if (distance < nearest) nearest = distance;
      }
      score +=
          _positionBaseBonus - math.min(nearest, 1.6) * _positionDistanceScale;
    }

    final edge = math.min(
      math.min(cue.position.x, TableGeometry.width - cue.position.x),
      math.min(cue.position.y, TableGeometry.height - cue.position.y),
    );
    if (edge < _railMargin) score -= _railPenalty;
    return score;
  }

  /// 没有可进攻线路时的防守杆：轻碰最近的合法目标球，避免空杆犯规。
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
    );
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
