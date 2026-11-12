import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/ball.dart';
import '../../theme/table_skin.dart';
import '../table_layout.dart';

/// 绘制台面上的球体：落地阴影、球体渐变、花色球带与号码。
class BallPainter {
  /// 球体显示列表统一按该基准半径录制，绘制时再缩放到实际球径。
  ///
  /// 显示列表记录的是矢量指令，缩放后依然清晰；这样窗口拖动、屏幕旋转
  /// 或不同球台尺寸都不会触发 16 颗球与号码文字的重录。
  static const double baseRadius = 24;

  final Map<String, TextPainter> _numbers = {};
  final List<ui.Picture?> _pictures = [];

  /// 软阴影用径向渐变代替逐球模糊，省掉每帧 16 次 MaskFilter。
  final Paint _shadowPaint = Paint();
  double _shadowRadius = -1;

  /// 球体按「球号」缓存显示列表，位置与球径变化只做画布平移与缩放。
  void paintShadows(Canvas canvas, TableLayout layout, Iterable<BallState> balls) {
    final radius = layout.ballRadius;
    _syncShadow(radius);
    final offset = Offset(radius * 0.16, radius * 0.24);
    for (final ball in balls) {
      if (!ball.active) continue;
      final center = layout.toCanvas(ball.position) + offset;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawCircle(Offset.zero, radius * 0.98, _shadowPaint);
      canvas.restore();
    }
  }

  void paintBall(Canvas canvas, TableLayout layout, BallState ball) {
    final picture = _pictureFor(ball);
    _draw(canvas, layout.toCanvas(ball.position), picture, layout.ballRadius / baseRadius);
  }

  /// 按球号取显示列表，首次绘制时才录制；列表按需增长以适配任意球号。
  ui.Picture _pictureFor(BallState ball) {
    final id = ball.id;
    if (id >= _pictures.length) _pictures.length = id + 1;
    return _pictures[id] ??= _record((canvas) {
      paintShape(canvas, ball, baseRadius);
    });
  }

  void _draw(Canvas canvas, Offset center, ui.Picture picture, double scale) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (scale != 1) canvas.scale(scale);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  void _syncShadow(double radius) {
    if ((_shadowRadius - radius).abs() < 0.01) return;
    _shadowRadius = radius;
    _shadowPaint.shader = ui.Gradient.radial(
      Offset.zero,
      radius * 0.98,
      [const Color(0x4D000000), const Color(0x3D000000), const Color(0x00000000)],
      [0, 0.72, 1],
    );
  }

  ui.Picture _record(void Function(Canvas) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  /// 在原点绘制单颗球：全色球通体着色，花色球白色球身配彩色球带。
  ///
  /// 调用方按固定基准半径录制显示列表，缩放交给画布变换。
  void paintShape(Canvas canvas, BallState ball, double radius) {
    const center = Offset.zero;
    final accent = ball.isCue ? const Color(0xFFF7F3E7) : ballColorOf(ball.id);
    final striped = ball.kind == BallKind.stripe;
    final body = striped ? const Color(0xFFF7F3E7) : accent;
    final highlighted = Color.lerp(body, Colors.white, ball.isCue ? 0.2 : 0.5)!;
    final shaded = Color.lerp(body, Colors.black, striped ? 0.3 : 0.42)!;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center - Offset(radius * 0.32, radius * 0.36),
          radius * 1.55,
          [highlighted, body, shaded],
          [0, 0.52, 1],
        ),
    );
    if (ball.kind == BallKind.stripe) _stripe(canvas, center, radius, accent);
    if (ball.isCue) {
      canvas.drawCircle(
        center - Offset(radius * 0.3, radius * 0.34),
        radius * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
      return;
    }
    _badge(canvas, center, radius, ball.id);
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

  void _stripe(Canvas canvas, Offset center, double radius, Color accent) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    final band = Rect.fromCenter(center: center, width: radius * 2.1, height: radius * 1.06);
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          band.topLeft,
          band.bottomRight,
          [
            Color.lerp(accent, Colors.white, 0.35)!,
            accent,
            Color.lerp(accent, Colors.black, 0.35)!,
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

  void _badge(Canvas canvas, Offset center, double radius, int id) {
    final badgeRadius = radius * 0.43;
    canvas.drawCircle(center, badgeRadius, Paint()..color = const Color(0xFFF8F4E8));
    canvas.drawCircle(
      center,
      badgeRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, radius * 0.045)
        ..color = Colors.black.withValues(alpha: 0.12),
    );
    final painter = _number(id, badgeRadius * 1.32);
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  TextPainter _number(int id, double size) {
    final key = '$id-${size.round()}';
    return _numbers.putIfAbsent(
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
