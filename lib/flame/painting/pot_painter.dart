import 'package:flutter/material.dart';

import '../../core/ball.dart';
import '../../core/table_geometry.dart';
import '../../core/vec.dart';
import '../../theme/table_skin.dart';
import '../table_layout.dart';

/// 一颗球落袋后的缩小动画数据。
class PotAnimation {
  PotAnimation({
    required this.from,
    required this.pocketIndex,
    required this.ballId,
    required this.kind,
  });

  final Vec2 from;
  final int pocketIndex;
  final int ballId;
  final BallKind kind;
  double progress = 0;
}

/// 绘制落袋动画：球从落袋点滑入袋口并逐渐缩小。
class PotPainter {
  void paint(Canvas canvas, TableLayout layout, PotAnimation animation) {
    final t = animation.progress.clamp(0.0, 1.0);
    final pocket = TableGeometry.pockets[animation.pocketIndex];
    final from = layout.toCanvas(animation.from);
    final to = layout.toCanvas(pocket);
    final center = Offset.lerp(from, to, Curves.easeIn.transform(t))!;
    final radius = layout.ballRadius * (1 - 0.72 * t);
    final color = ballColorOf(animation.ballId);
    final alpha = (1 - t).clamp(0.0, 1.0);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    if (animation.kind == BallKind.stripe) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFF8F4E8).withValues(alpha: alpha),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: radius * 2.2,
          height: radius * 1.1,
        ),
        Paint()..color = color.withValues(alpha: alpha),
      );
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
    canvas.restore();
  }
}
