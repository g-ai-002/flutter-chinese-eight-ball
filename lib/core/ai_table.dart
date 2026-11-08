import 'dart:math' as math;

import 'ball.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// 一条可行的进球线路：母球击球角与几何评分。
class AiLine {
  const AiLine({required this.angle, required this.score});

  final double angle;

  /// 切角与距离的综合分，越高越容易打进。
  final double score;
}

/// AI 的台面分析：目标球筛选、进球线路、阻挡判断与库边 / 袋口距离。
///
/// 进攻候选、走位评分与防守评分共用这里的几何判定，保证三者的
/// 「好线路」标准一致。
class AiTable {
  AiTable._();

  /// 切球角过小说明几乎擦边，直接放弃这条线路。
  static const double _minCut = 0.16;

  /// 幽灵球额外外移，避免目标球与袋口方向完全共线。
  static const double _ghostClearance = 0.0012;

  /// 当前球手的合法目标球：清台后只打黑八，开放球台排除黑八。
  static List<BallState> legalTargets(List<BallState> balls, PlayerGroup? group, bool onEight) {
    if (onEight) return _pick(balls, eight: true);
    if (group == null) return _pick(balls, eight: false);
    return _ownOrEight(balls, group.kind);
  }

  /// 对手的合法目标球：己方清台后对手要打黑八。
  static List<BallState> opponentTargets(List<BallState> balls, PlayerGroup? group) {
    if (group == null) return _pick(balls, eight: false);
    return _ownOrEight(balls, group == PlayerGroup.solids ? BallKind.stripe : BallKind.solid);
  }

  /// 台面上仍在场的球；[eight] 为 true 只取黑八，否则排除黑八。
  static List<BallState> _pick(List<BallState> balls, {required bool eight}) => [
    for (final ball in balls)
      if (ball.active && !ball.isCue && ball.isEight == eight) ball,
  ];

  /// 指定花色的球；本方清台后改打黑八。
  static List<BallState> _ownOrEight(List<BallState> balls, BallKind kind) {
    final own = [
      for (final ball in balls)
        if (ball.active && !ball.isCue && ball.kind == kind) ball,
    ];
    return own.isNotEmpty ? own : _pick(balls, eight: true);
  }

  /// 评估母球 → 目标球 → 指定袋口的线路；不可行返回 null。
  static AiLine? lineFor(Vec2 cue, BallState target, int pocketIndex, List<BallState> balls) {
    final pocket = TableGeometry.pockets[pocketIndex];
    final pdx = pocket.x - target.position.x;
    final pdy = pocket.y - target.position.y;
    final pocketLength = math.sqrt(pdx * pdx + pdy * pdy);
    if (pocketLength < 1e-9) return null;
    final dirX = pdx / pocketLength;
    final dirY = pdy / pocketLength;

    const offset = TableGeometry.ballRadius * 2 + _ghostClearance;
    final ghost = Vec2(target.position.x - dirX * offset, target.position.y - dirY * offset);
    if (ghost.x < 0 ||
        ghost.x > TableGeometry.width ||
        ghost.y < 0 ||
        ghost.y > TableGeometry.height) {
      return null;
    }

    final angle = angleOf(cue, ghost);
    final cut = math.cos(angle) * dirX + math.sin(angle) * dirY;
    if (cut < _minCut) return null;
    if (pathBlocked(from: cue, to: ghost, balls: balls, ignoreA: 0, ignoreB: target.id)) {
      return null;
    }
    if (pathBlocked(from: target.position, to: pocket, balls: balls, ignoreA: target.id)) {
      return null;
    }

    final distance = cue.distanceTo(target.position);
    return AiLine(angle: angle, score: cut * 3.6 - distance * 0.35);
  }

  /// 线段是否被其他球挡住；[ignoreA] / [ignoreB] 指定的球不参与判定。
  static bool pathBlocked({
    required Vec2 from,
    required Vec2 to,
    required List<BallState> balls,
    int ignoreA = -1,
    int ignoreB = -1,
  }) {
    const clearance = TableGeometry.ballRadius * 2 - 0.002;
    const clearanceSquared = clearance * clearance;
    for (final ball in balls) {
      if (!ball.active || ball.id == ignoreA || ball.id == ignoreB) continue;
      if (distanceSquaredToSegment(ball.position, from, to) < clearanceSquared) {
        return true;
      }
    }
    return false;
  }

  /// 点到最近库边的距离。
  static double edgeDistance(Vec2 point) => math.min(
    math.min(point.x, TableGeometry.width - point.x),
    math.min(point.y, TableGeometry.height - point.y),
  );

  /// 点到最近袋口的距离。
  static double pocketDistance(Vec2 point) {
    var nearest = double.infinity;
    for (final pocket in TableGeometry.pockets) {
      final distance = point.distanceTo(pocket);
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  /// 对手下一杆的最佳线路分；越低越安全。
  static double opponentThreat(Vec2 cue, List<BallState> targets, List<BallState> balls) {
    var best = 0.0;
    for (final target in targets) {
      for (var pocketIndex = 0; pocketIndex < TableGeometry.pockets.length; pocketIndex++) {
        final line = lineFor(cue, target, pocketIndex, balls);
        if (line != null && line.score > best) best = line.score;
      }
    }
    return best;
  }

  /// 母球到对手目标球被完全遮挡的数量，用于给「藏球」加分。
  static int hiddenTargets(Vec2 cue, List<BallState> targets, List<BallState> balls) {
    var hidden = 0;
    for (final target in targets) {
      if (pathBlocked(
        from: cue,
        to: target.position,
        balls: balls,
        ignoreA: 0,
        ignoreB: target.id,
      )) {
        hidden++;
      }
    }
    return hidden;
  }
}
