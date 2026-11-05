import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/table_geometry.dart';
import '../../core/vec.dart';
import '../../theme/table_skin.dart';
import '../table_layout.dart';
import 'paint_utils.dart';

/// 绘制球台本体：木框、台呢、开球线与球点、袋口、库边刻度与台面标识。
///
/// 只负责静态台面，球体、瞄准线等动态元素由其他 painter 处理。
class TablePainter {
  TextPainter? _brandPainter;
  double _brandScale = 0;

  void paint(Canvas canvas, TableLayout layout, TableSkin skin) {
    _paintRails(canvas, layout, skin);
    _paintCloth(canvas, layout, skin);
    _paintMarkings(canvas, layout, skin);
    _paintPockets(canvas, layout, skin);
    _paintDiamonds(canvas, layout, skin);
    _paintBrand(canvas, layout);
  }

  void _paintRails(Canvas canvas, TableLayout layout, TableSkin skin) {
    final tableRect = layout.tableRect;
    final radius = Radius.circular(layout.ballRadius * 1.35);

    // 斜向高光让木质外框显得有厚度。
    final railPaint = Paint()
      ..shader = ui.Gradient.linear(
        tableRect.topLeft,
        tableRect.bottomRight,
        [Color.lerp(skin.rail, Colors.white, 0.16)!, skin.rail, skin.railEdge],
        [0, 0.45, 1],
      );
    canvas.drawRRect(RRect.fromRectAndRadius(tableRect, radius), railPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tableRect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  void _paintCloth(Canvas canvas, TableLayout layout, TableSkin skin) {
    final surfaceRect = layout.surfaceRect;

    // 中心偏亮、四周略暗，模拟顶光。
    canvas.drawRect(
      surfaceRect,
      Paint()
        ..shader = ui.Gradient.radial(
          surfaceRect.center,
          surfaceRect.longestSide * 0.72,
          [skin.clothLight, skin.cloth, skin.clothDark],
          [0, 0.55, 1],
        ),
    );
    canvas.drawRect(
      surfaceRect,
      Paint()
        ..shader = ui.Gradient.linear(
          surfaceRect.topLeft,
          surfaceRect.center,
          [Colors.black.withValues(alpha: 0.28), Colors.transparent],
          [0, 0.55],
        ),
    );
    canvas.drawRect(
      surfaceRect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = layout.scale * 0.006
        ..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  void _paintMarkings(Canvas canvas, TableLayout layout, TableSkin skin) {
    final paint = Paint()
      ..color = skin.marking
      ..strokeWidth = math.max(1, layout.scale * 0.0028)
      ..style = PaintingStyle.stroke;

    final headX = layout.toCanvas(const Vec2(TableGeometry.headStringX, 0)).dx;
    drawDashedLine(
      canvas,
      Offset(headX, layout.surfaceRect.top),
      Offset(headX, layout.surfaceRect.bottom),
      paint,
      dash: layout.scale * 0.045,
      gap: layout.scale * 0.03,
    );

    final spotPaint = Paint()..color = skin.marking;
    for (final spot in [TableGeometry.footSpot, TableGeometry.headSpot]) {
      canvas.drawCircle(
        layout.toCanvas(spot),
        math.max(1.2, layout.scale * 0.0035),
        spotPaint,
      );
    }
  }

  void _paintPockets(Canvas canvas, TableLayout layout, TableSkin skin) {
    for (final pocket in TableGeometry.pockets) {
      final center = layout.toCanvas(pocket);
      final radius = layout.pocketRadius * 1.25;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(center, radius, [
            Colors.black,
            skin.pocket,
          ]),
      );
      canvas.drawCircle(
        center,
        radius * 1.06,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, layout.scale * 0.004)
          ..color = skin.diamond.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        center + Offset(0, radius * 0.14),
        radius * 0.82,
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
    }
  }

  void _paintDiamonds(Canvas canvas, TableLayout layout, TableSkin skin) {
    final sizePx = math.max(2.0, layout.scale * 0.012);
    final paint = Paint()..color = skin.diamond.withValues(alpha: 0.85);
    final surface = layout.surfaceRect;
    final railOffset = TableLayout.railWidth * layout.scale * 0.5;

    void diamond(double x, double y) {
      final path = Path()
        ..moveTo(x, y - sizePx)
        ..lineTo(x + sizePx, y)
        ..lineTo(x, y + sizePx)
        ..lineTo(x - sizePx, y)
        ..close();
      canvas.drawPath(path, paint);
    }

    for (var i = 1; i <= 7; i++) {
      if (i == 4) continue;
      final x = surface.left + surface.width * i / 8;
      diamond(x, surface.top - railOffset);
      diamond(x, surface.bottom + railOffset);
    }
    for (var i = 1; i <= 3; i++) {
      final y = surface.top + surface.height * i / 4;
      diamond(surface.left - railOffset, y);
      diamond(surface.right + railOffset, y);
    }
  }

  void _paintBrand(Canvas canvas, TableLayout layout) {
    if (_brandPainter == null || (_brandScale - layout.scale).abs() > 0.5) {
      _brandScale = layout.scale;
      _brandPainter = TextPainter(
        text: TextSpan(
          text: '中 式 黑 八',
          style: TextStyle(
            fontSize: layout.scale * 0.055,
            letterSpacing: layout.scale * 0.02,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final painter = _brandPainter!;
    painter.paint(
      canvas,
      Offset(
        layout.surfaceRect.center.dx - painter.width / 2,
        layout.surfaceRect.center.dy - painter.height / 2,
      ),
    );
  }
}
