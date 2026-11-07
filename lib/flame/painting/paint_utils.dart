import 'dart:math' as math;
import 'dart:ui';

/// 按固定长度画虚线，供瞄准线与开球线共用。
void drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  double dash = 8,
  double gap = 6,
}) {
  final delta = end - start;
  final length = delta.distance;
  if (length < 1) return;
  final direction = delta / length;
  var distance = 0.0;
  while (distance < length) {
    final segmentEnd = math.min(distance + dash, length);
    canvas.drawLine(start + direction * distance, start + direction * segmentEnd, paint);
    distance += dash + gap;
  }
}
