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

  double cross(Vec2 other) => x * other.y - y * other.x;

  double distanceTo(Vec2 other) => (this - other).length;

  double distanceSquaredTo(Vec2 other) => (this - other).lengthSquared;

  Vec2 clamp(double minX, double maxX, double minY, double maxY) =>
      Vec2(x.clamp(minX, maxX), y.clamp(minY, maxY));

  Vec2 rotated(double radians) {
    final cosA = math.cos(radians);
    final sinA = math.sin(radians);
    return Vec2(x * cosA - y * sinA, x * sinA + y * cosA);
  }

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
  final delta = to - from;
  if (delta.lengthSquared < 1e-12) return 0;
  return math.atan2(delta.y, delta.x);
}

/// 点到线段的最近距离，用于判断击球路线是否被其他球阻挡。
double distanceToSegment(Vec2 point, Vec2 start, Vec2 end) {
  final segment = end - start;
  final lengthSquared = segment.lengthSquared;
  if (lengthSquared < 1e-12) return point.distanceTo(start);
  final t = ((point - start).dot(segment) / lengthSquared).clamp(0.0, 1.0);
  return point.distanceTo(start + segment * t);
}
