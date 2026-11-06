import 'dart:math' as math;

import 'ai_safety.dart';
import 'ai_shot.dart';
import 'ai_table.dart';
import 'ai_weights.dart';
import 'ball.dart';
import 'physics.dart';
import 'rules.dart';
import 'table_geometry.dart';
import 'vec.dart';

export 'ai_shot.dart';

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
///
/// 进攻把握不足时交给 [AiSafety] 试算防守杆，两边得分接近时仍选进攻。
class EightBallAi {
  EightBallAi({math.Random? random})
    : _random = random ?? math.Random(),
      _safety = const AiSafety();

  final math.Random _random;
  final AiSafety _safety;

  AiShot decide({
    required List<BallState> balls,
    required PlayerGroup? group,
    required bool onEight,
    AiTuning tuning = AiTuning.normal,
  }) {
    final cue = balls.firstWhere((ball) => ball.isCue);
    final targets = AiTable.legalTargets(balls, group, onEight);

    if (!cue.active || targets.isEmpty) {
      return AiShot(
        angle: _random.nextDouble() * math.pi * 2,
        power: 0.5,
        score: 0,
      );
    }

    final candidates = _attackCandidates(cue.position, targets, balls)
      ..sort((a, b) => b.geometryScore.compareTo(a.geometryScore));
    final limited = candidates.take(tuning.candidateLimit);

    final attack = _bestEvaluatedShot(
      candidates: limited,
      balls: balls,
      group: group,
      onEight: onEight,
    );
    // 只有进攻把握不足时才试算防守，避免每次都多跑一轮物理模拟。
    var chosen = attack;
    if (attack == null || attack.score < AiWeights.attackConfidence) {
      final safety = _safety.choose(
        balls: balls,
        targets: targets,
        group: group,
        onEight: onEight,
      );
      chosen = _preferShot(attack, safety);
    }
    chosen ??= _safety.fallback(balls: balls, targets: targets);
    return AiShot(
      angle: _applyError(chosen.angle, tuning.aimError),
      power: (chosen.power + _symmetric(tuning.powerError)).clamp(0.15, 1.0),
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
    if (safety.score > attack.score + AiWeights.safetyGainMargin) {
      return safety;
    }
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
        final line = AiTable.lineFor(cue, target, pocketIndex, balls);
        if (line == null) continue;
        candidates.add(
          _Candidate(
            angle: line.angle,
            geometryScore: line.score,
            targetBallId: target.id,
            pocketIndex: pocketIndex,
          ),
        );
      }
    }
    return candidates;
  }

  AiShot? _bestEvaluatedShot({
    required Iterable<_Candidate> candidates,
    required List<BallState> balls,
    required PlayerGroup? group,
    required bool onEight,
  }) {
    AiShot? best;
    for (final candidate in candidates) {
      for (final power in AiWeights.powerLevels) {
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
        score -= AiWeights.scratchPenalty;
      } else if (id == 8) {
        // 指袋规则下，只有落进候选袋口才算赢。
        final pocketMatched = outcome.pocketOf(8) == targetPocket;
        score += onEight && pocketMatched
            ? AiWeights.eightWinBonus
            : -AiWeights.eightLossPenalty;
      } else if (group == null || MatchRules.kindOfBall(id) == group.kind) {
        score += AiWeights.ownPotBonus;
      } else {
        score -= AiWeights.opponentPotPenalty;
      }
    }
    return score;
  }

  double _contactScore(ShotOutcome outcome, PlayerGroup? group, bool onEight) {
    if (outcome.firstContact == null) return -AiWeights.noContactPenalty;
    if (onEight) return 0;

    final kind = MatchRules.kindOfBall(outcome.firstContact!);
    final expected = group?.kind;
    var score = 0.0;
    if (expected != null && kind != expected) {
      score -= AiWeights.wrongGroupPenalty;
    }
    if (kind == BallKind.eight) score -= AiWeights.eightContactPenalty;
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
        final line = AiTable.lineFor(
          cue.position,
          ball,
          pocketIndex,
          simulation.balls,
        );
        if (line != null && line.score > bestNext) bestNext = line.score;
      }
    }
    if (bestNext.isFinite) {
      score +=
          AiWeights.positionBaseBonus + bestNext * AiWeights.positionLineScale;
    } else if (remaining.isNotEmpty) {
      var nearest = double.infinity;
      for (final ball in remaining) {
        final distance = cue.position.distanceTo(ball.position);
        if (distance < nearest) nearest = distance;
      }
      score +=
          AiWeights.positionBaseBonus * 0.5 -
          math.min(nearest, 1.6) * AiWeights.positionDistanceScale;
    }

    final edge = AiTable.edgeDistance(cue.position);
    if (edge < AiWeights.railMargin) score -= AiWeights.railPenalty;
    if (edge < TableGeometry.ballRadius * 1.2) {
      score -= AiWeights.railPenalty * 0.6;
    }
    if (AiTable.pocketDistance(cue.position) <
        TableGeometry.pocketRadius * 1.6) {
      score -= AiWeights.pocketPenalty;
    }
    return score;
  }

  double _applyError(double angle, double error) => angle + _symmetric(error);

  double _symmetric(double magnitude) =>
      (_random.nextDouble() * 2 - 1) * magnitude;
}
