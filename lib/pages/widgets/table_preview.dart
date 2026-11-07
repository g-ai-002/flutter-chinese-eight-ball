import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ball.dart';
import '../../core/table_geometry.dart';
import '../../core/vec.dart';
import '../../flame/table_layout.dart';
import '../../flame/table_scene.dart';
import '../../theme/table_skin.dart';

/// 首页球台缩略图：复用对局渲染层绘制台面、摆球与球杆。
class TablePreview extends StatelessWidget {
  const TablePreview({super.key, required this.skin});

  final TableSkin skin;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: TableLayout.aspectRatio,
      child: CustomPaint(painter: _TablePreviewPainter(skin), size: Size.infinite),
    );
  }
}

class _TablePreviewPainter extends CustomPainter {
  _TablePreviewPainter(this.skin);

  final TableSkin skin;
  final TableScene _scene = TableScene();

  @override
  void paint(Canvas canvas, Size size) {
    final layout = TableLayout(size);
    _scene.paintTable(canvas, layout, skin);
    final balls = [
      for (final ball in TableGeometry.rackBalls())
        if (!ball.isCue) ball,
      BallState(spec: kCueBall, position: const Vec2(TableGeometry.width * 0.3, 0.9)),
    ];
    _scene.paintBalls(canvas, layout, balls);

    canvas.drawLine(
      layout.toCanvas(const Vec2(TableGeometry.width * 0.2, 0.35)),
      layout.toCanvas(const Vec2(TableGeometry.width * 0.06, 0.18)),
      Paint()
        ..color = const Color(0xFFC79A5B)
        ..strokeWidth = math.max(2, layout.scale * 0.012)
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TablePreviewPainter oldDelegate) => oldDelegate.skin != skin;
}
