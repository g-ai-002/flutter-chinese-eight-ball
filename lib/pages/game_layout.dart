import 'dart:math' as math;
import 'dart:ui';

import '../flame/table_layout.dart';

/// 对局页的浮层几何。
///
/// 顶部信息条与底部操作条使用固定高度，其余空间全部交给球台；回合、球组与
/// 提示文案的长度不参与计算，因此任何状态变化都不会移动或缩放球台。
class GameLayout {
  GameLayout(this.page) {
    final dockHeight = singleRow ? dockRowHeight : dockStackHeight;
    header = Rect.fromLTWH(pagePadding, pagePadding, contentWidth, headerHeight);
    dock = Rect.fromLTWH(
      pagePadding,
      page.height - pagePadding - dockHeight,
      contentWidth,
      dockHeight,
    );
    final core = Rect.fromLTRB(
      pagePadding,
      header.bottom + gap,
      page.width - pagePadding,
      dock.top - gap,
    );
    final reserved = inline ? null : _infoRect(core);
    final tableArea = reserved == null
        ? core
        : Rect.fromLTRB(core.left, core.top, core.right, math.max(core.top, reserved.top - gap));
    tableSize = TableLayout.fit(tableArea.size);
    tableRect = Rect.fromCenter(
      center: tableArea.center,
      width: tableSize.width,
      height: tableSize.height,
    );
    info = reserved == null ? null : _infoRect(core, below: tableRect.bottom + gap);
    panelWidth = math.min(panelMaxWidth, page.width - pagePadding * 2 - 24);
    panel = Rect.fromLTRB(
      page.width - pagePadding - panelWidth,
      header.bottom + gap,
      page.width - pagePadding,
      dock.top - gap,
    );
  }

  /// 页面四周留白。
  static const double pagePadding = 8;
  static const double headerHeight = 50;
  static const double infoHeight = 80;
  static const double gap = 8;
  static const double dockRowHeight = 60;
  static const double dockStackHeight = 102;
  static const double panelMaxWidth = 320;

  /// 信息条内联球组与提示的最小宽度，窄于此宽度改为球台下方悬浮提示条。
  static const double inlineWidth = 800;

  /// 力度控制单行排布的最小宽度。
  static const double singleRowWidth = 560;

  final Size page;
  late final Rect header;
  late final Rect dock;
  late final Rect tableRect;
  late final Size tableSize;
  late final double panelWidth;

  /// 可收起的球局浮层区域，叠在球台上方。
  late final Rect panel;

  /// 球台下方的悬浮提示条；宽屏把提示内联到顶部条时为空。
  late final Rect? info;

  double get contentWidth => page.width - pagePadding * 2;

  bool get inline => page.width >= inlineWidth;

  bool get singleRow => page.width >= singleRowWidth;

  /// 提示条贴在球台下沿；球台较高时回落到操作条上方。
  Rect _infoRect(Rect core, {double? below}) {
    final width = math.max(0.0, math.min(core.width, 640.0));
    final bottom = core.bottom - infoHeight;
    final top = below == null ? bottom : math.min(bottom, below);
    return Rect.fromLTWH(core.center.dx - width / 2, top, width, infoHeight);
  }
}
