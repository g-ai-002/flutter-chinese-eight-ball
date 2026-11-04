import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/ball.dart';
import '../../core/table_geometry.dart';
import '../../core/vec.dart';
import '../../theme/table_skin.dart';
import '../../flame/table_layout.dart';

/// 首页球台缩略图：真实比例的台面、摆球与球杆。
class TablePreview extends StatelessWidget {
  const TablePreview({super.key, required this.skin});

  final TableSkin skin;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.88,
      child: CustomPaint(
        painter: _TablePreviewPainter(skin),
        size: Size.infinite,
      ),
    );
  }
}

class _TablePreviewPainter extends CustomPainter {
  const _TablePreviewPainter(this.skin);

  final TableSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = TableLayout(size);
    final tableRect = layout.tableRect;
    final surface = layout.surfaceRect;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        tableRect,
        Radius.circular(layout.ballRadius * 1.3),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          tableRect.topLeft,
          tableRect.bottomRight,
          [
            Color.lerp(skin.rail, Colors.white, 0.16)!,
            skin.rail,
            skin.railEdge,
          ],
          [0, 0.45, 1],
        ),
    );
    canvas.drawRect(
      surface,
      Paint()
        ..shader = ui.Gradient.radial(
          surface.center,
          surface.longestSide * 0.7,
          [skin.clothLight, skin.cloth, skin.clothDark],
          [0, 0.55, 1],
        ),
    );

    for (final pocket in TableGeometry.pockets) {
      canvas.drawCircle(
        layout.toCanvas(pocket),
        layout.pocketRadius * 1.2,
        Paint()..color = skin.pocket,
      );
    }

    final headX = layout.toCanvas(const Vec2(TableGeometry.headStringX, 0)).dx;
    canvas.drawLine(
      Offset(headX, surface.top),
      Offset(headX, surface.bottom),
      Paint()
        ..color = skin.marking
        ..strokeWidth = 1,
    );

    for (final ball in TableGeometry.rackBalls()) {
      if (ball.isCue) {
        _drawBall(
          canvas,
          layout.toCanvas(const Vec2(TableGeometry.width * 0.3, 0.9)),
          layout.ballRadius * 0.92,
          const Color(0xFFF8F4E8),
          false,
          null,
        );
        continue;
      }
      _drawBall(
        canvas,
        layout.toCanvas(ball.position),
        layout.ballRadius * 0.92,
        ballColorOf(ball.id),
        ball.kind == BallKind.stripe,
        ball.id,
      );
    }

    final cueFrom = layout.toCanvas(
      const Vec2(TableGeometry.width * 0.2, 0.35),
    );
    final cueTo = layout.toCanvas(const Vec2(TableGeometry.width * 0.06, 0.18));
    canvas.drawLine(
      cueFrom,
      cueTo,
      Paint()
        ..color = const Color(0xFFC79A5B)
        ..strokeWidth = math.max(2, layout.scale * 0.012)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBall(
    Canvas canvas,
    Offset center,
    double radius,
    Color base,
    bool stripe,
    int? id,
  ) {
    if (stripe) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFF8F4E8),
      );
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: radius * 2.1,
          height: radius * 1.15,
        ),
        Paint()..color = base,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            center - Offset(radius * 0.3, radius * 0.35),
            radius * 1.6,
            [
              Color.lerp(base, Colors.white, 0.4)!,
              base,
              Color.lerp(base, Colors.black, 0.35)!,
            ],
            [0, 0.55, 1],
          ),
      );
    }
    if (id != null && radius > 6) {
      canvas.drawCircle(
        center,
        radius * 0.42,
        Paint()..color = const Color(0xFFF8F4E8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TablePreviewPainter oldDelegate) =>
      oldDelegate.skin != skin;
}
