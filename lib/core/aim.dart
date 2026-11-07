import 'dart:math' as math;

import 'ball.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// 瞄准辅助线：母球撞击点（幽灵球）、目标球去向与库边落点。
class AimSolution {
  const AimSolution({
    required this.direction,
    this.ghostCenter,
    this.targetBallId,
    this.targetDirection,
    this.cushionPoint,
  });

  final Vec2 direction;
  final Vec2? ghostCenter;
  final int? targetBallId;
  final Vec2? targetDirection;
  final Vec2? cushionPoint;
}

/// 沿瞄准方向投射母球，找到首个接触的球或库边。
AimSolution solveAim({
  required Vec2 cue,
  required Iterable<BallState> balls,
  required double angle,
}) {
  final direction = directionOf(angle);
  const diameter = TableGeometry.ballRadius * 2;

  int? hitId;
  var nearest = double.infinity;
  Vec2? ghost;
  for (final ball in balls) {
    if (!ball.active || ball.isCue) continue;
    final offset = ball.position - cue;
    final projection = offset.dot(direction);
    if (projection <= 0) continue;
    final perpendicularSquared = offset.lengthSquared - projection * projection;
    if (perpendicularSquared > diameter * diameter) continue;
    final entry = projection - math.sqrt(diameter * diameter - perpendicularSquared);
    final distance = entry < 0 ? 0.0 : entry;
    if (distance >= nearest) continue;
    nearest = distance;
    hitId = ball.id;
    ghost = cue + direction * distance;
  }

  if (ghost != null && hitId != null) {
    final targetBall = balls.firstWhere((ball) => ball.id == hitId);
    return AimSolution(
      direction: direction,
      ghostCenter: ghost,
      targetBallId: hitId,
      targetDirection: (targetBall.position - ghost).normalized,
    );
  }

  return AimSolution(direction: direction, cushionPoint: cushionPointOf(cue, direction));
}

/// 射线与台面内沿的交点，返回最先碰到的库边点。
Vec2? cushionPointOf(Vec2 origin, Vec2 direction) {
  const radius = TableGeometry.ballRadius;
  const minX = radius;
  const maxX = TableGeometry.width - radius;
  const minY = radius;
  const maxY = TableGeometry.height - radius;
  var best = double.infinity;
  Vec2? point;

  void consider(double t) {
    if (t <= 1e-6 || t >= best) return;
    final candidate = origin + direction * t;
    if (candidate.x < minX - 1e-6 ||
        candidate.x > maxX + 1e-6 ||
        candidate.y < minY - 1e-6 ||
        candidate.y > maxY + 1e-6) {
      return;
    }
    best = t;
    point = candidate;
  }

  if (direction.x.abs() > 1e-9) {
    consider((minX - origin.x) / direction.x);
    consider((maxX - origin.x) / direction.x);
  }
  if (direction.y.abs() > 1e-9) {
    consider((minY - origin.y) / direction.y);
    consider((maxY - origin.y) / direction.y);
  }
  return point;
}
