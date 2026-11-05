import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/aim.dart';
import '../../core/ball.dart';
import '../../core/match_controller.dart';
import '../../core/table_geometry.dart';
import '../../core/vec.dart';
import '../table_layout.dart';
import 'paint_utils.dart';

/// 绘制瞄准辅助线、球杆与自由球摆放预览。
class AimPainter {
  void paintGuide(
    Canvas canvas,
    TableLayout layout,
    MatchController controller,
  ) {
    final aim = solveAim(
      cue: controller.cuePosition,
      balls: controller.balls,
      angle: controller.aimAngle,
    );
    final start = layout.toCanvas(controller.cuePosition);
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = math.max(1, layout.scale * 0.0032)
      ..strokeCap = StrokeCap.round;

    if (aim.ghostCenter != null) {
      _paintGhostBall(canvas, layout, controller, aim, start, guidePaint);
    } else if (aim.cushionPoint != null) {
      final end = layout.toCanvas(aim.cushionPoint!);
      drawDashedLine(canvas, start, end, guidePaint);
      canvas.drawCircle(
        end,
        layout.ballRadius * 0.55,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }
  }

  void _paintGhostBall(
    Canvas canvas,
    TableLayout layout,
    MatchController controller,
    AimSolution aim,
    Offset start,
    Paint guidePaint,
  ) {
    final ghost = layout.toCanvas(aim.ghostCenter!);
    drawDashedLine(canvas, start, ghost, guidePaint);
    canvas.drawCircle(
      ghost,
      layout.ballRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, layout.scale * 0.0035)
        ..color = Colors.white.withValues(alpha: 0.7),
    );

    final target = _ballById(controller.balls, aim.targetBallId);
    if (target == null) return;
    final targetCenter = layout.toCanvas(target.position);
    final direction = aim.targetDirection ?? Vec2.zero;
    final end =
        targetCenter + Offset(direction.x, direction.y) * layout.scale * 0.42;
    canvas.drawLine(
      targetCenter,
      end,
      Paint()
        ..color = const Color(0xFFFFD98A).withValues(alpha: 0.85)
        ..strokeWidth = math.max(1, layout.scale * 0.0032)
        ..strokeCap = StrokeCap.round,
    );
  }

  void paintCue(Canvas canvas, TableLayout layout, MatchController controller) {
    final direction = directionOf(controller.aimAngle);
    final center = layout.toCanvas(controller.cuePosition);
    final pullback = layout.ballRadius * (1.3 + controller.power * 4.2);
    final tip = center - Offset(direction.x, direction.y) * pullback;
    final butt =
        center -
        Offset(direction.x, direction.y) * (pullback + layout.scale * 1.08);
    final normal = Offset(-direction.y, direction.x);
    final tipHalf = layout.scale * 0.0042;
    final buttHalf = layout.scale * 0.013;

    final path = Path()
      ..moveTo(tip.dx + normal.dx * tipHalf, tip.dy + normal.dy * tipHalf)
      ..lineTo(butt.dx + normal.dx * buttHalf, butt.dy + normal.dy * buttHalf)
      ..lineTo(butt.dx - normal.dx * buttHalf, butt.dy - normal.dy * buttHalf)
      ..lineTo(tip.dx - normal.dx * tipHalf, tip.dy - normal.dy * tipHalf)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          tip,
          butt,
          [
            const Color(0xFFE9D3A6),
            const Color(0xFFC79A5B),
            const Color(0xFF8B5A2B),
          ],
          [0, 0.55, 1],
        ),
    );
    canvas.drawLine(
      tip,
      butt,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..strokeWidth = math.max(0.5, layout.scale * 0.0015),
    );

    // 先角与皮头。
    final ferruleEnd =
        tip + Offset(direction.x, direction.y) * layout.scale * 0.05;
    canvas.drawLine(
      tip,
      ferruleEnd,
      Paint()
        ..color = const Color(0xFFF4F0E4)
        ..strokeWidth = layout.scale * 0.009,
    );
    canvas.drawLine(
      ferruleEnd,
      ferruleEnd + Offset(direction.x, direction.y) * layout.scale * 0.012,
      Paint()
        ..color = const Color(0xFF2E6FA8)
        ..strokeWidth = layout.scale * 0.009
        ..strokeCap = StrokeCap.round,
    );
  }

  void paintPlacementPreview(
    Canvas canvas,
    TableLayout layout,
    MatchController controller,
    Vec2 preview,
  ) {
    final valid = TableGeometry.isValidCuePlacement(
      preview,
      obstacles: controller.balls,
    );
    final center = layout.toCanvas(preview);
    canvas.drawCircle(
      center,
      layout.ballRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      layout.ballRadius * 1.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, layout.scale * 0.004)
        ..color = (valid ? const Color(0xFF6EC3A2) : const Color(0xFFE07A72))
            .withValues(alpha: 0.9),
    );
  }

  BallState? _ballById(List<BallState> balls, int? id) {
    if (id == null) return null;
    for (final ball in balls) {
      if (ball.id == id) return ball;
    }
    return null;
  }
}
