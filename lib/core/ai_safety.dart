import 'dart:math' as math;

import 'ai_shot.dart';
import 'ai_table.dart';
import 'ai_weights.dart';
import 'ball.dart';
import 'physics.dart';
import 'rules.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// 防守杆评估：轻碰合法目标球，把母球留在贴库、藏球或远离对手的位置。
///
/// 只负责枚举与打分，不参与进攻路线选择；是否采用防守杆由
/// `EightBallAi` 比较两侧得分后决定。
class AiSafety {
  const AiSafety();

  /// 返回得分最高的防守杆；没有任何合法接触线路时返回 null。
  AiShot? choose({
    required List<BallState> balls,
    required List<BallState> targets,
    required PlayerGroup? group,
    required bool onEight,
  }) {
    final cue = balls.firstWhere((ball) => ball.isCue);
    AiShot? best;
    for (final target in targets) {
      for (final angle in _angles(cue.position, target)) {
        for (final power in AiWeights.safetyPowers) {
          final simulation = ShotSimulation(balls: balls);
          simulation.strike(angle, power);
          final outcome = simulation.simulateToRest(limit: 8);
          final score = _score(
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

  /// 完全找不到防守线路时的兜底：轻碰最近合法球，避免空杆犯规。
  AiShot fallback({required List<BallState> balls, required List<BallState> targets}) {
    final cue = balls.firstWhere((ball) => ball.isCue);
    final target = targets.reduce(
      (best, ball) =>
          cue.position.distanceTo(ball.position) < cue.position.distanceTo(best.position)
          ? ball
          : best,
    );
    return AiShot(
      angle: angleOf(cue.position, target.position),
      power: AiWeights.fallbackPower,
      score: -100,
      targetBallId: target.id,
      isSafety: true,
    );
  }

  /// 正碰与薄碰各一条线路，薄碰更容易把母球留在库边。
  Iterable<double> _angles(Vec2 cue, BallState target) sync* {
    final direction = (target.position - cue).normalized;
    if (direction.lengthSquared < 0.5) return;
    yield angleOf(cue, target.position);
    final ghost = target.position + direction.perpendicular * (TableGeometry.ballRadius * 0.9);
    yield angleOf(cue, ghost);
  }

  /// 防守杆评分：先保证合法接触，再比较母球安全度与对手下一杆威胁。
  double _score({
    required ShotOutcome outcome,
    required ShotSimulation simulation,
    required PlayerGroup? group,
    required bool onEight,
  }) {
    final firstContact = outcome.firstContact;
    if (firstContact == null) return -1;

    var score = AiWeights.safetyBase;
    final firstKind = MatchRules.kindOfBall(firstContact);
    final expected = group?.kind;
    if (outcome.cuePotted) score -= AiWeights.safetyScratchPenalty;
    if (outcome.eightPotted) score -= AiWeights.safetyEightPotPenalty;
    if (onEight) {
      if (firstKind != BallKind.eight) {
        score -= AiWeights.safetyWrongContactPenalty;
      }
    } else {
      if (expected != null && firstKind != expected) {
        score -= AiWeights.safetyWrongContactPenalty;
      }
      if (firstKind == BallKind.eight) {
        score -= AiWeights.safetyEightContactPenalty;
      }
    }

    for (final event in outcome.potted) {
      final id = event.ballId;
      if (id == 0 || id == 8) continue;
      if (group != null && MatchRules.kindOfBall(id) == group.kind) {
        score += AiWeights.ownPotBonus * 0.5;
      } else {
        score -= AiWeights.safetyOpponentPotPenalty;
      }
    }
    // 把目标球推向库边，对手下一杆的进球角度会更差。
    for (final ball in simulation.balls) {
      if (ball.id == firstContact &&
          ball.active &&
          AiTable.edgeDistance(ball.position) < AiWeights.railMargin) {
        score += AiWeights.safetyTargetRailBonus;
      }
    }

    final cue = simulation.cueBall;
    if (!cue.active) return score;
    final edge = AiTable.edgeDistance(cue.position);
    if (edge < AiWeights.railMargin) score += AiWeights.safetyRailBonus;
    if (edge < TableGeometry.ballRadius * 1.2) {
      score += AiWeights.safetyRailBonus * 0.5;
    }

    final opponents = AiTable.opponentTargets(simulation.balls, group);
    if (opponents.isEmpty) return score;
    var nearest = double.infinity;
    for (final ball in opponents) {
      final distance = cue.position.distanceTo(ball.position);
      if (distance < nearest) nearest = distance;
    }
    score += math.min(nearest, 2.4) * AiWeights.safetyDistanceScale;
    score -=
        AiTable.opponentThreat(cue.position, opponents, simulation.balls) *
        AiWeights.safetyThreatPenalty;
    score +=
        AiTable.hiddenTargets(cue.position, opponents, simulation.balls) *
        AiWeights.safetyHiddenBonus;
    return score;
  }
}
