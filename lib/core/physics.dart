import 'dart:math' as math;

import 'ball.dart';
import 'table_geometry.dart';
import 'vec.dart';

/// 击球过程中的即时事件，界面层用于播放音效与落袋动画。
sealed class ShotEvent {
  const ShotEvent();
}

class BallImpact extends ShotEvent {
  const BallImpact({required this.strength, required this.ballBall});

  final double strength;
  final bool ballBall;
}

class BallPocketed extends ShotEvent {
  const BallPocketed({
    required this.ballId,
    required this.pocketIndex,
    required this.position,
  });

  final int ballId;
  final int pocketIndex;
  final Vec2 position;
}

/// 一杆结束后的客观事实，规则引擎据此裁定。
class ShotOutcome {
  ShotOutcome({
    required this.potted,
    required this.firstContact,
    required this.cushionAfterContact,
    required this.timedOut,
  });

  final List<BallPocketed> potted;
  final int? firstContact;
  final bool cushionAfterContact;
  final bool timedOut;

  bool get cuePotted => potted.any((event) => event.ballId == 0);
  bool get eightPotted => potted.any((event) => event.ballId == 8);
  bool get anyPotted => potted.isNotEmpty;

  List<int> get pottedIds => [for (final event in potted) event.ballId];

  /// 本杆首个落袋的目标球（不含母球），用于开球后确定球组。
  int? get firstPottedObject {
    for (final event in potted) {
      if (event.ballId != 0) return event.ballId;
    }
    return null;
  }
}

/// 台球物理模拟：等质量弹性碰撞、库边反弹、滚动摩擦与落袋判定。
///
/// 用固定子步长积分，保证高速度下也不会穿透球体；实时动画与 AI 试算
/// 使用同一套步进逻辑，因此 AI 预判结果与真实击球一致。
class ShotSimulation {
  ShotSimulation({required Iterable<BallState> balls})
    : balls = BallState.cloneAll(balls);

  static const double maxShotSpeed = 4.6;
  static const double ballRestitution = 0.94;
  static const double cushionRestitution = 0.72;
  static const double _stopSpeed = 0.012;
  static const double _maxSubstep = 1 / 240;
  static const double maxDuration = 24;

  final List<BallState> balls;
  final List<ShotEvent> events = [];

  int? firstContact;
  bool cushionAfterContact = false;
  bool timedOut = false;
  double elapsed = 0;
  bool struck = false;

  BallState get cueBall => balls.firstWhere((ball) => ball.isCue);

  bool get settled {
    if (timedOut) return true;
    for (final ball in balls) {
      if (ball.active && ball.speed > _stopSpeed) return false;
    }
    return true;
  }

  bool get cuePotted => !cueBall.active;

  /// 出杆：把母球按角度与力度推出，power 取值 0~1。
  void strike(double angle, double power) {
    final cue = cueBall;
    if (!cue.active) return;
    final strength = power.clamp(0.0, 1.0) * maxShotSpeed;
    cue.velocity = directionOf(angle) * math.max(strength, 0.12);
    struck = true;
    elapsed = 0;
  }

  void placeCue(Vec2 position) {
    final cue = cueBall;
    cue
      ..position = position
      ..velocity = Vec2.zero
      ..active = true;
  }

  /// 推进物理时间，返回 true 表示仍有球在运动。
  bool step(double dt) {
    if (settled || dt <= 0) return false;
    final clamped = math.min(dt, 0.05);
    final substeps = math.max(1, (clamped / _maxSubstep).ceil());
    final sub = clamped / substeps;
    for (var i = 0; i < substeps; i++) {
      _substep(sub);
    }
    elapsed += clamped;
    if (elapsed >= maxDuration) timedOut = true;
    return true;
  }

  /// 一次性跑完这一杆（AI 试算使用），最多模拟 [limit] 秒。
  ShotOutcome simulateToRest({double limit = 12}) {
    while (!settled && elapsed < limit) {
      step(1 / 120);
    }
    return outcome();
  }

  void _substep(double dt) {
    for (final ball in balls) {
      if (!ball.active) continue;
      ball.position = ball.position + ball.velocity * dt;
    }
    _resolveBallCollisions();
    _capturePockets();
    _bounceCushions();
    _applyFriction(dt);
  }

  void _resolveBallCollisions() {
    for (var i = 0; i < balls.length; i++) {
      final a = balls[i];
      if (!a.active) continue;
      for (var j = i + 1; j < balls.length; j++) {
        final b = balls[j];
        if (!b.active) continue;
        final delta = b.position - a.position;
        final distance = delta.length;
        const diameter = TableGeometry.ballRadius * 2;
        if (distance >= diameter) continue;

        final normal = distance < 1e-7
            ? const Vec2(1, 0)
            : delta * (1 / distance);
        final overlap = diameter - distance;
        a.position = a.position - normal * (overlap / 2);
        b.position = b.position + normal * (overlap / 2);

        if (a.isCue && firstContact == null) firstContact = b.id;
        if (b.isCue && firstContact == null) firstContact = a.id;

        final relative = a.velocity - b.velocity;
        final closing = relative.dot(normal);
        if (closing <= 0) continue;

        final transfer = closing * ballRestitution;
        a.velocity = a.velocity - normal * transfer;
        b.velocity = b.velocity + normal * transfer;
        if (closing > 0.18) {
          events.add(BallImpact(strength: closing, ballBall: true));
        }
      }
    }
  }

  void _capturePockets() {
    for (final ball in balls) {
      if (!ball.active) continue;
      for (var index = 0; index < TableGeometry.pockets.length; index++) {
        final pocket = TableGeometry.pockets[index];
        if (ball.position.distanceTo(pocket) <= TableGeometry.pocketRadius) {
          final event = BallPocketed(
            ballId: ball.id,
            pocketIndex: index,
            position: ball.position,
          );
          ball
            ..active = false
            ..velocity = Vec2.zero;
          events.add(event);
          break;
        }
      }
    }
  }

  void _bounceCushions() {
    const radius = TableGeometry.ballRadius;
    for (final ball in balls) {
      if (!ball.active) continue;
      var position = ball.position;
      var velocity = ball.velocity;
      var bounced = false;
      if (position.x < radius) {
        position = Vec2(radius, position.y);
        if (velocity.x < 0) {
          velocity = Vec2(-velocity.x * cushionRestitution, velocity.y * 0.98);
          bounced = true;
        }
      } else if (position.x > TableGeometry.width - radius) {
        position = Vec2(TableGeometry.width - radius, position.y);
        if (velocity.x > 0) {
          velocity = Vec2(-velocity.x * cushionRestitution, velocity.y * 0.98);
          bounced = true;
        }
      }
      if (position.y < radius) {
        position = Vec2(position.x, radius);
        if (velocity.y < 0) {
          velocity = Vec2(velocity.x * 0.98, -velocity.y * cushionRestitution);
          bounced = true;
        }
      } else if (position.y > TableGeometry.height - radius) {
        position = Vec2(position.x, TableGeometry.height - radius);
        if (velocity.y > 0) {
          velocity = Vec2(velocity.x * 0.98, -velocity.y * cushionRestitution);
          bounced = true;
        }
      }
      ball
        ..position = position
        ..velocity = velocity;
      if (bounced) {
        if (firstContact != null) cushionAfterContact = true;
        if (velocity.length > 0.2) {
          events.add(BallImpact(strength: velocity.length, ballBall: false));
        }
      }
    }
  }

  void _applyFriction(double dt) {
    for (final ball in balls) {
      if (!ball.active) continue;
      final speed = ball.speed;
      if (speed <= _stopSpeed) {
        ball.velocity = Vec2.zero;
        continue;
      }
      final deceleration = 1.15 + 0.45 * speed;
      final nextSpeed = math.max(0.0, speed - deceleration * dt);
      ball.velocity = nextSpeed <= _stopSpeed
          ? Vec2.zero
          : ball.velocity * (nextSpeed / speed);
    }
  }

  ShotOutcome outcome() => ShotOutcome(
    potted: [
      for (final event in events)
        if (event is BallPocketed) event,
    ],
    firstContact: firstContact,
    cushionAfterContact: cushionAfterContact,
    timedOut: timedOut,
  );
}
