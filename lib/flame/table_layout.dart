import 'dart:math' as math;
import 'dart:ui';

import '../core/table_geometry.dart';
import '../core/vec.dart';

/// 台面坐标（米）与画布像素之间的映射，渲染与手势共用同一份换算。
class TableLayout {
  TableLayout(this.size) {
    const totalWidth = TableGeometry.width + railWidth * 2;
    const totalHeight = TableGeometry.height + railWidth * 2;
    scale = math.min(size.width / totalWidth, size.height / totalHeight);
    origin = Offset(
      (size.width - TableGeometry.width * scale) / 2,
      (size.height - TableGeometry.height * scale) / 2,
    );
  }

  static const double railWidth = 0.095;

  /// 球台整体（含木框）的宽高比，页面按此比例预留空间。
  static const double aspectRatio =
      (TableGeometry.width + railWidth * 2) /
      (TableGeometry.height + railWidth * 2);

  final Size size;
  late final double scale;
  late final Offset origin;

  double get ballRadius => TableGeometry.ballRadius * scale;
  double get pocketRadius => TableGeometry.pocketRadius * scale;

  Offset toCanvas(Vec2 point) =>
      Offset(origin.dx + point.x * scale, origin.dy + point.y * scale);

  Vec2 toTable(Offset point) =>
      Vec2((point.dx - origin.dx) / scale, (point.dy - origin.dy) / scale);

  Rect get surfaceRect => Rect.fromLTWH(
    origin.dx,
    origin.dy,
    TableGeometry.width * scale,
    TableGeometry.height * scale,
  );

  Rect get tableRect => Rect.fromLTWH(
    origin.dx - railWidth * scale,
    origin.dy - railWidth * scale,
    (TableGeometry.width + railWidth * 2) * scale,
    (TableGeometry.height + railWidth * 2) * scale,
  );

  bool containsTablePoint(Offset local) {
    final point = toTable(local);
    return point.x >= -railWidth &&
        point.x <= TableGeometry.width + railWidth &&
        point.y >= -railWidth &&
        point.y <= TableGeometry.height + railWidth;
  }
}
