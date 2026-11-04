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

    final candidates = <_Candidate>[];
    for (final target in targets) {
      for (
        var pocketIndex = 0;
        pocketIndex < TableGeometry.pockets.length;
        pocketIndex++
      ) {
        final pocket = TableGeometry.pockets[pocketIndex];
        final pocketDirection = (pocket - target.position).normalized;
        if (pocketDirection.lengthSquared < 0.5) continue;
        final ghost =
            target.position -
            pocketDirection * (TableGeometry.ballRadius * 2 + 0.0012);
        if (ghost.x < 0 ||
            ghost.x > TableGeometry.width ||
            ghost.y < 0 ||
            ghost.y > TableGeometry.height) {
          continue;
        }
        final angle = angleOf(cue.position, ghost);
        final aimDirection = directionOf(angle);
        final cut = aimDirection.dot(pocketDirection);
        if (cut < 0.16) continue;
        if (_pathBlocked(
          from: cue.position,
          to: ghost,
          balls: balls,
          ignore: {0, target.id},
        )) {
          continue;
        }
        if (_pathBlocked(
          from: target.position,
          to: pocket,
          balls: balls,
          ignore: {target.id},
        )) {
          continue;
        }
        final distance = cue.position.distanceTo(target.position);
        final geometry = cut * 2.4 - distance * 0.35 + cut * 1.2;
        candidates.add(
          _Candidate(
            angle: angle,
            geometryScore: geometry,
            targetBallId: target.id,
            pocketIndex: pocketIndex,
          ),
        );
      }
    }

    candidates.sort((a, b) => b.geometryScore.compareTo(a.geometryScore));
    final limited = candidates.take(difficulty.candidateLimit).toList();

    AiShot? best;
    for (final candidate in limited) {
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

    best ??= _safetyShot(balls, targets, group, onEight);
    return AiShot(
      angle: _applyError(best.angle, difficulty.aimError),
      power: (best.power + _symmetric(difficulty.powerError)).clamp(0.15, 1.0),
      score: best.score,
      targetBallId: best.targetBallId,
      pocketIndex: best.pocketIndex,
    );
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

    var score = 0.0;
    for (final event in outcome.potted) {
      final id = event.ballId;
      if (id == 0) {
        score -= 260;
      } else if (id == 8) {
        score += onEight ? 5000 : -5000;
      } else if (group == null) {
        score += 150;
      } else if (MatchRules.kindOfBall(id) == group.kind) {
        score += 150;
      } else {
        score -= 90;
      }
    }

    if (outcome.firstContact == null) {
      score -= 420;
    } else if (!onEight) {
      final kind = MatchRules.kindOfBall(outcome.firstContact!);
      final expected = group?.kind;
      if (expected != null && kind != expected) score -= 320;
      if (kind == BallKind.eight) score -= 380;
    }

    final cue = simulation.cueBall;
    if (cue.active) {
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
        score += 40 - math.min(nearest, 1.6) * 30;
      }
      final edge = math.min(
        math.min(cue.position.x, TableGeometry.width - cue.position.x),
        math.min(cue.position.y, TableGeometry.height - cue.position.y),
      );
      if (edge < 0.06) score -= 25;
    }

    return AiShot(
      angle: angle,
      power: power,
      score: score,
      targetBallId: targetBallId,
      pocketIndex: pocketIndex,
    );
  }

  /// 没有可进攻线路时的防守杆：轻碰最近的合法目标球，避免空杆犯规。
  AiShot _safetyShot(
    List<BallState> balls,
    List<BallState> targets,
    PlayerGroup? group,
    bool onEight,
  ) {
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
