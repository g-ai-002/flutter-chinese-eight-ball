import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/aim.dart';
import '../core/ball.dart';
import '../core/match_controller.dart';
import '../core/physics.dart';
import '../core/table_geometry.dart';
import '../core/vec.dart';
import '../providers/settings_provider.dart';
import '../services/sound_service.dart';
import '../theme/table_skin.dart';
import 'table_layout.dart';

/// 球台渲染与击球特效：台呢、木框、袋口、球体、瞄准线与球杆。
///
/// 组件本身不处理手势，瞄准与摆球由页面层的 GestureDetector 转发，
/// 这样 Flame 只负责画面与物理推进，交互逻辑更易测试。
class TableComponent extends PositionComponent {
  TableComponent({
    required this.controller,
    required this.settings,
    this.placementPreview,
  });

  final MatchController controller;
  final SettingsProvider settings;

  /// 摆球时手指所在位置，用于绘制半透明母球预览。
  final ValueNotifier<Vec2?>? placementPreview;

  final List<_PotAnimation> _potAnimations = [];
  final Map<String, TextPainter> _numberPainters = {};
  TextPainter? _brandPainter;
  double _brandScale = 0;

  MatchPhase _lastPhase = MatchPhase.aiming;
  double _lastImpactAt = -1;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _handlePhaseSound();
    _drainEffects();
    for (final animation in _potAnimations) {
      animation.progress += dt / 0.36;
    }
    _potAnimations.removeWhere((animation) => animation.progress >= 1);
  }

  void _handlePhaseSound() {
    final phase = controller.phase;
    if (phase != _lastPhase) {
      if (phase == MatchPhase.shooting) {
        SoundService.play(SoundFeedback.strike);
      } else if (phase == MatchPhase.gameOver) {
        final winner = controller.rules.winner;
        final playerWin =
            controller.mode == GameMode.twoPlayers ||
            winner == controller.humanSide;
        SoundService.play(playerWin ? SoundFeedback.win : SoundFeedback.lose);
      }
      _lastPhase = phase;
    }
  }

  void _drainEffects() {
    if (controller.pendingEffects.isEmpty) return;
    for (final event in controller.pendingEffects) {
      switch (event) {
        case BallImpact():
          if (_time - _lastImpactAt < 0.04) continue;
          _lastImpactAt = _time;
          final volume = (event.strength / 3.2).clamp(0.12, 0.85);
          SoundService.play(SoundFeedback.impact, volume: volume);
        case BallPocketed():
          SoundService.play(SoundFeedback.pocket, volume: 0.85);
          final ball = controller.simulation.balls.firstWhere(
            (item) => item.id == event.ballId,
          );
          _potAnimations.add(
            _PotAnimation(
              from: event.position,
              pocketIndex: event.pocketIndex,
              ballId: event.ballId,
              kind: ball.kind,
            ),
          );
      }
    }
    controller.pendingEffects.clear();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final layout = TableLayout(Size(size.x, size.y));
    _drawTable(canvas, layout);
    _drawShadows(canvas, layout);
    for (final ball in controller.balls) {
      if (!ball.active) continue;
      _drawBall(canvas, layout, ball);
    }
    if (controller.phase == MatchPhase.aiming && controller.cueBall.active) {
      _drawCue(canvas, layout);
      if (settings.showAimGuide) _drawAim(canvas, layout);
    }
    _drawPlacementPreview(canvas, layout);
    for (final animation in _potAnimations) {
      _drawPotAnimation(canvas, layout, animation);
    }
  }

  // ---------------------------------------------------------------------------
  // 球台
  // ---------------------------------------------------------------------------

  void _drawTable(Canvas canvas, TableLayout layout) {
    final skin = settings.tableSkin;
    final tableRect = layout.tableRect;
    final surfaceRect = layout.surfaceRect;
    final radius = Radius.circular(layout.ballRadius * 1.35);

    // 木质外框：斜向高光让边框显得有厚度。
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

    // 台呢：中心偏亮、四周略暗，模拟顶光。
    final clothPaint = Paint()
      ..shader = ui.Gradient.radial(
        surfaceRect.center,
        surfaceRect.longestSide * 0.72,
        [skin.clothLight, skin.cloth, skin.clothDark],
        [0, 0.55, 1],
      );
    canvas.drawRect(surfaceRect, clothPaint);

    // 台边阴影，突出台呢低于木框的层次。
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

    _drawMarkings(canvas, layout, skin);
    _drawPockets(canvas, layout, skin);
    _drawDiamonds(canvas, layout, skin);
    _drawBrand(canvas, layout);
  }

  void _drawMarkings(Canvas canvas, TableLayout layout, TableSkin skin) {
    final paint = Paint()
      ..color = skin.marking
      ..strokeWidth = math.max(1, layout.scale * 0.0028)
      ..style = PaintingStyle.stroke;

    final headX = layout.toCanvas(const Vec2(TableGeometry.headStringX, 0)).dx;
    _drawDashedLine(
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

  void _drawPockets(Canvas canvas, TableLayout layout, TableSkin skin) {
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

  void _drawDiamonds(Canvas canvas, TableLayout layout, TableSkin skin) {
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

  void _drawBrand(Canvas canvas, TableLayout layout) {
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

  // ---------------------------------------------------------------------------
  // 球体
  // ---------------------------------------------------------------------------

  void _drawShadows(Canvas canvas, TableLayout layout) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.26)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        layout.ballRadius * 0.18,
      );
    for (final ball in controller.balls) {
      if (!ball.active) continue;
      canvas.drawCircle(
        layout.toCanvas(ball.position) +
            Offset(layout.ballRadius * 0.16, layout.ballRadius * 0.24),
        layout.ballRadius * 0.98,
        paint,
      );
    }
  }

  void _drawBall(Canvas canvas, TableLayout layout, BallState ball) {
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

    if (ball.isCue) {
      canvas.drawCircle(
        center - Offset(radius * 0.3, radius * 0.34),
        radius * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
      return;
    }

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
    final painter = _numberPainter(ball.id, badgeRadius * 1.32);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );

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

  // ---------------------------------------------------------------------------
  // 瞄准线与球杆
  // ---------------------------------------------------------------------------

  void _drawAim(Canvas canvas, TableLayout layout) {
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
      final ghost = layout.toCanvas(aim.ghostCenter!);
      _drawDashedLine(canvas, start, ghost, guidePaint);
      canvas.drawCircle(
        ghost,
        layout.ballRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, layout.scale * 0.0035)
          ..color = Colors.white.withValues(alpha: 0.7),
      );
      final target = controller.balls.where(
        (ball) => ball.id == aim.targetBallId,
      );
      if (target.isEmpty) return;
      final targetCenter = layout.toCanvas(target.first.position);
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
    } else if (aim.cushionPoint != null) {
      final end = layout.toCanvas(aim.cushionPoint!);
      _drawDashedLine(canvas, start, end, guidePaint);
      canvas.drawCircle(
        end,
        layout.ballRadius * 0.55,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }
  }

  void _drawCue(Canvas canvas, TableLayout layout) {
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

  // ---------------------------------------------------------------------------
  // 落袋动画与摆球预览
  // ---------------------------------------------------------------------------

  void _drawPotAnimation(
    Canvas canvas,
    TableLayout layout,
    _PotAnimation animation,
  ) {
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

  void _drawPlacementPreview(Canvas canvas, TableLayout layout) {
    if (controller.phase != MatchPhase.placingCue) return;
    final preview = placementPreview?.value ?? controller.cueBall.position;
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

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double? dash,
    double? gap,
  }) {
    final delta = end - start;
    final length = delta.distance;
    if (length < 1) return;
    final direction = delta / length;
    final dashLength = dash ?? 8.0;
    final gapLength = gap ?? 6.0;
    var distance = 0.0;
    while (distance < length) {
      final segmentEnd = math.min(distance + dashLength, length);
      canvas.drawLine(
        start + direction * distance,
        start + direction * segmentEnd,
        paint,
      );
      distance += dashLength + gapLength;
    }
  }
}

class _PotAnimation {
  _PotAnimation({
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
