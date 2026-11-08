import 'package:flutter/material.dart';

import '../core/ball.dart';
import '../core/physics.dart';
import '../theme/table_skin.dart';
import 'painting/ball_painter.dart';
import 'painting/pot_painter.dart';
import 'painting/table_painter.dart';
import 'table_layout.dart';

/// 球台静态画面与落袋动画的共享渲染层。
///
/// 实时对局与回放共用同一套绘制顺序、布局缓存与落袋动画推进；实时对局
/// 额外叠加的瞄准线与摆球预览仍由组件自行绘制。
class TableScene {
  static const double _potDuration = 0.36;

  final TablePainter _tablePainter = TablePainter();
  final BallPainter _ballPainter = BallPainter();
  final PotPainter _potPainter = PotPainter();
  final List<PotAnimation> _pots = [];

  TableLayout? _layout;
  Size _layoutSize = Size.zero;

  TableLayout layoutFor(Size size) {
    final cached = _layout;
    if (cached != null && _layoutSize == size) return cached;
    _layoutSize = size;
    return _layout = TableLayout(size);
  }

  void update(double dt) {
    if (_pots.isEmpty) return;
    for (final animation in _pots) {
      animation.progress += dt / _potDuration;
    }
    _pots.removeWhere((animation) => animation.progress >= 1);
  }

  /// 按球号在 [balls] 里取球型，实时对局与回放共用同一段落袋动画。
  void addPot(BallPocketed event, Iterable<BallState> balls) {
    final ball = balls.firstWhere((item) => item.id == event.ballId);
    _pots.add(
      PotAnimation(
        from: event.position,
        pocketIndex: event.pocketIndex,
        ballId: event.ballId,
        kind: ball.kind,
      ),
    );
  }

  void paintTable(Canvas canvas, TableLayout layout, TableSkin skin) {
    _tablePainter.paint(canvas, layout, skin);
  }

  void paintBalls(Canvas canvas, TableLayout layout, List<BallState> balls) {
    _ballPainter.paintShadows(canvas, layout, balls);
    for (final ball in balls) {
      if (!ball.active) continue;
      _ballPainter.paintBall(canvas, layout, ball);
    }
  }

  void paintPots(Canvas canvas, TableLayout layout) {
    for (final animation in _pots) {
      _potPainter.paint(canvas, layout, animation);
    }
  }
}
