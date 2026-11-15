import 'package:material_ui/material_ui.dart';

import '../../flame/painting/preview_painter.dart';
import '../../flame/table_layout.dart';
import '../../theme/table_skin.dart';

/// 首页球台缩略图：复用对局渲染层绘制台面、摆球与球杆。
///
/// 显示列表按基准宽度录制并缓存，窗口缩放与主题切换只做缩放绘制。
class TablePreview extends StatelessWidget {
  const TablePreview({super.key, required this.skin});

  /// 首页不同页面实例共用同一份缓存，缩略图内容与尺寸无关。
  static final PreviewPainter _painter = PreviewPainter();

  final TableSkin skin;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: TableLayout.aspectRatio,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TablePreviewPainter(_painter, skin),
          isComplex: true,
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _TablePreviewPainter extends CustomPainter {
  _TablePreviewPainter(this.painter, this.skin);

  final PreviewPainter painter;
  final TableSkin skin;

  @override
  void paint(Canvas canvas, Size size) => painter.paint(canvas, size, skin);

  @override
  bool shouldRepaint(covariant _TablePreviewPainter oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.painter != painter;
}
