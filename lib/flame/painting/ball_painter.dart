import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/ball.dart';
import '../../theme/table_skin.dart';
import '../table_layout.dart';

/// 绘制台面上的球体：落地阴影、球体渐变、花色球带与号码。
class BallPainter {
  final Map<String, TextPainter> _numberPainters = {};

  void paintShadows(
    Canvas canvas,
    TableLayout layout,
    Iterable<BallState> balls,
  ) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        layout.ballRadius * 0.18,
      );
    for (final ball in balls) {
      if (!ball.active) continue;
      canvas.drawCircle(
        layout.toCanvas(ball.position) +
            Offset(layout.ballRadius * 0.16, layout.ballRadius * 0.24),
        layout.ballRadius * 0.98,
        paint,
      );
    }
  }

  void paintBall(Canvas canvas, TableLayout layout, BallState ball) {
    final center = layout.toCanvas(ball.position);
    final radius = layout.ballRadius;
    final base = ball.isCue ? const Color(0xFFF7F3E7) : ballColorOf(ball.id);
    final highlighted = Color.lerp(base, Colors.white, ball.isCue ? 0.2 : 0.5)!;
    final shaded = Color.lerp(base, Colors.black, 0.42)!;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center - Offset(radius * 0.32, radius * 0.36),
          radius * 1.55,
          [highlighted, base, shaded],
          [0, 0.52, 1],
        ),
    );

    if (ball.kind == BallKind.stripe) {
      _paintStripeBand(canvas, center, radius, base);
    }

    if (ball.isCue) {
      canvas.drawCircle(
        center - Offset(radius * 0.3, radius * 0.34),
        radius * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
      return;
    }

    _paintNumberBadge(canvas, center, radius, ball.id);

    // 顶部高光，让球体更立体。
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      math.pi * 1.08,
      math.pi * 0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, radius * 0.08)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _paintStripeBand(
    Canvas canvas,
    Offset center,
    double radius,
    Color base,
  ) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final band = Rect.fromCenter(
      center: center,
      width: radius * 2.1,
      height: radius * 1.12,
    );
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          band.topLeft,
          band.bottomRight,
          [
            Color.lerp(base, Colors.white, 0.35)!,
            base,
            Color.lerp(base, Colors.black, 0.3)!,
          ],
          [0, 0.55, 1],
        ),
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, radius * 0.05)
        ..color = Colors.black.withValues(alpha: 0.16),
    );
  }

  void _paintNumberBadge(Canvas canvas, Offset center, double radius, int id) {
    final badgeRadius = radius * 0.43;
    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()..color = const Color(0xFFF8F4E8),
    );
    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, radius * 0.045)
        ..color = Colors.black.withValues(alpha: 0.12),
    );
    final painter = _numberPainter(id, badgeRadius * 1.32);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  TextPainter _numberPainter(int id, double size) {
    final key = '$id-${size.round()}';
    return _numberPainters.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: '$id',
          style: TextStyle(
            fontSize: size,
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }
}
