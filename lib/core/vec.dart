import 'dart:math' as math;

/// 不可变二维向量，台球物理与 AI 共用。
///
/// 台面坐标以米为单位：原点在台面左上角，x 向右、y 向下。
class Vec2 {
  const Vec2(this.x, this.y);

  final double x;
  final double y;

  static const Vec2 zero = Vec2(0, 0);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scale) => Vec2(x * scale, y * scale);
  Vec2 operator -() => Vec2(-x, -y);

  double get length => math.sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;

  Vec2 get normalized {
    final len = length;
    if (len < 1e-9) return zero;
    return Vec2(x / len, y / len);
  }

  /// 逆时针旋转 90°，用于求碰撞法线。
  Vec2 get perpendicular => Vec2(-y, x);

  double dot(Vec2 other) => x * other.x + y * other.y;

  double distanceTo(Vec2 other) => math.sqrt(distanceSquaredTo(other));

  double distanceSquaredTo(Vec2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  Vec2 clamp(double minX, double maxX, double minY, double maxY) =>
      Vec2(x.clamp(minX, maxX), y.clamp(minY, maxY));

  @override
  bool operator ==(Object other) =>
      other is Vec2 && (other.x - x).abs() < 1e-9 && (other.y - y).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(x.round(), y.round());

  @override
  String toString() => 'Vec2(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)})';
}

/// 方向角（弧度），0 指向 +x，逆时针为正。
Vec2 directionOf(double angle) => Vec2(math.cos(angle), math.sin(angle));

/// 两点连线的方向角，两点重合时返回 0。
double angleOf(Vec2 from, Vec2 to) {
  final dx = to.x - from.x;
  final dy = to.y - from.y;
  if (dx * dx + dy * dy < 1e-12) return 0;
  return math.atan2(dy, dx);
}

/// 点到线段的最短距离平方，用于路线遮挡判定（不做开方、不建临时向量）。
double distanceSquaredToSegment(Vec2 point, Vec2 start, Vec2 end) {
  final sx = end.x - start.x;
  final sy = end.y - start.y;
  final lengthSquared = sx * sx + sy * sy;
  final px = point.x - start.x;
  final py = point.y - start.y;
  if (lengthSquared < 1e-12) return px * px + py * py;
  final t = ((px * sx + py * sy) / lengthSquared).clamp(0.0, 1.0);
  final dx = px - sx * t;
  final dy = py - sy * t;
  return dx * dx + dy * dy;
}
