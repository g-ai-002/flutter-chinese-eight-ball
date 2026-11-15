import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/ball.dart';
import '../../core/table_geometry.dart';
import '../../core/vec.dart';
import '../../theme/table_skin.dart';
import '../table_layout.dart';
import '../table_scene.dart';

/// 首页球台缩略图的显示列表缓存。
///
/// 缩略图的台面与摆球固定不变，按基准宽度录制一次后按实际宽度缩放绘制：
/// 桌面拖动窗口、切换主题或反复进出首页都不会重录台面与 16 颗球。
class PreviewPainter {
  PreviewPainter({this.baseWidth = 480});

  /// 录制显示列表使用的基准宽度（逻辑像素）。
  final double baseWidth;

  final TableScene _scene = TableScene();
  final Map<TableSkin, ui.Picture> _pictures = {};
  final Paint _cuePaint = Paint()
    ..color = const Color(0xFFC79A5B)
    ..strokeCap = StrokeCap.round;

  late final List<BallState> _balls = [
    for (final ball in TableGeometry.rackBalls())
      if (!ball.isCue) ball,
    BallState(spec: kCueBall, position: const Vec2(TableGeometry.width * 0.3, 0.9)),
  ];

  /// 已录制的配色数量，用于验证同一配色只录制一次。
  @visibleForTesting
  int get pictureCount => _pictures.length;

  ui.Picture pictureFor(TableSkin skin) => _pictures.putIfAbsent(skin, () => _record(skin));

  void paint(Canvas canvas, Size size, TableSkin skin) {
    if (size.isEmpty) return;
    final base = Size(baseWidth, baseWidth / TableLayout.aspectRatio);
    final scale = math.min(size.width / base.width, size.height / base.height);
    canvas.save();
    canvas.translate(
      (size.width - base.width * scale) / 2,
      (size.height - base.height * scale) / 2,
    );
    if (scale != 1) canvas.scale(scale, scale);
    canvas.drawPicture(pictureFor(skin));
    canvas.restore();
  }

  ui.Picture _record(TableSkin skin) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final layout = TableLayout(Size(baseWidth, baseWidth / TableLayout.aspectRatio));
    _scene.paintTable(canvas, layout, skin);
    _scene.paintBalls(canvas, layout, _balls);
    _cuePaint.strokeWidth = math.max(2, layout.scale * 0.012);
    canvas.drawLine(
      layout.toCanvas(const Vec2(TableGeometry.width * 0.2, 0.35)),
      layout.toCanvas(const Vec2(TableGeometry.width * 0.06, 0.18)),
      _cuePaint,
    );
    return recorder.endRecording();
  }
}
