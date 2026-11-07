import 'dart:math' as math;
import 'dart:ui';

import '../flame/table_layout.dart';

/// 对局页的浮层几何。
///
/// 竖向空间充足时在球台下方留出悬浮提示条；横屏手机、分屏与矮窗口进入紧凑
/// 模式，提示内联到顶部条，球台独占中间区域。顶部条、操作条与球台尺寸只由
/// 页面尺寸决定，回合与提示文案的长度不参与计算。
class GameLayout {
  GameLayout(this.page) {
    compact = page.height < compactHeight;
    final dockHeight = singleRow
        ? (compact ? dockCompactHeight : dockRowHeight)
        : (compact ? dockStackCompactHeight : dockStackHeight);
    header = Rect.fromLTWH(
      pagePadding,
      pagePadding,
      contentWidth,
      compact ? compactHeaderHeight : headerHeight,
    );
    dock = Rect.fromLTWH(
      pagePadding,
      page.height - pagePadding - dockHeight,
      contentWidth,
      dockHeight,
    );
    final top = header.bottom + gap;
    final core = Rect.fromLTRB(
      pagePadding,
      top,
      math.max(pagePadding, page.width - pagePadding),
      math.max(top, dock.top - gap),
    );
    // 只有竖向空间充足时才为提示条预留位置，矮窗口把提示交给顶部条。
    final withInfo = !compact && !inline;
    final tableArea = withInfo
        ? Rect.fromLTRB(
            core.left,
            core.top,
            core.right,
            math.max(core.top, core.bottom - infoHeight - gap),
          )
        : core;
    tableSize = TableLayout.fit(tableArea.size);
    tableRect = Rect.fromCenter(
      center: tableArea.center,
      width: tableSize.width,
      height: tableSize.height,
    );
    info = withInfo ? _infoRect(core, below: tableRect.bottom + gap) : null;
    panelWidth = math.max(0.0, math.min(panelMaxWidth, page.width - pagePadding * 2 - 24));
    final panelLeft = math.max(pagePadding, page.width - pagePadding - panelWidth);
    panel = Rect.fromLTRB(
      panelLeft,
      header.bottom + gap,
      math.max(panelLeft, page.width - pagePadding),
      math.max(header.bottom + gap, dock.top - gap),
    );
  }

  /// 页面四周留白。
  static const double pagePadding = 8;
  static const double headerHeight = 50;
  static const double compactHeaderHeight = 48;
  static const double infoHeight = 80;
  static const double gap = 8;
  static const double dockRowHeight = 60;
  static const double dockStackHeight = 102;
  static const double dockCompactHeight = 56;
  static const double dockStackCompactHeight = 96;
  static const double panelMaxWidth = 320;

  /// 信息条内联球组与提示的最小宽度，窄于此宽度改为球台下方悬浮提示条。
  static const double inlineWidth = 800;

  /// 力度控制单行排布的最小宽度。
  static const double singleRowWidth = 560;

  /// 紧凑模式下力度控制单行排布的最小宽度。
  static const double compactSingleRowWidth = 480;

  /// 低于此高度视为矮屏，切换紧凑布局。
  static const double compactHeight = 560;

  final Size page;

  /// 矮屏紧凑布局：顶部条与操作条压缩，提示条内联到顶部条。
  late final bool compact;
  late final Rect header;
  late final Rect dock;
  late final Rect tableRect;
  late final Size tableSize;
  late final double panelWidth;

  /// 可收起的球局浮层区域，叠在球台上方。
  late final Rect panel;

  /// 球台下方的悬浮提示条；紧凑模式与宽屏内联时为空。
  late final Rect? info;

  double get contentWidth => math.max(0.0, page.width - pagePadding * 2);

  bool get inline => page.width >= inlineWidth;

  bool get singleRow => page.width >= (compact ? compactSingleRowWidth : singleRowWidth);

  /// 提示条贴在球台下沿；球台较高时回落到操作条上方。
  Rect _infoRect(Rect core, {double? below}) {
    final width = math.max(0.0, math.min(core.width, 640.0));
    final bottom = core.bottom - infoHeight;
    final top = below == null ? bottom : math.min(bottom, below);
    return Rect.fromLTWH(core.center.dx - width / 2, math.max(core.top, top), width, infoHeight);
  }
}
