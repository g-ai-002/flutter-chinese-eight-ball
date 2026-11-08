import 'dart:math' as math;
import 'dart:ui';

import '../flame/table_layout.dart';

/// 对局页的浮层几何。
///
/// 球台始终显示在页面正中，顶部信息条、球局浮层与底部操作条都叠在四周；
/// 竖向空间充足时提示条悬浮在球台上方，宽屏与紧凑布局把提示内联到顶部条。
/// 横屏矮屏进入沉浸布局：球台吃满整页，顶部条与操作条改为半透明浮层叠在
/// 球台上下沿，不再为浮层让出高度。
/// 浮层高度只由页面尺寸决定，回合与提示文案的长度不参与计算。
class GameLayout {
  GameLayout(this.page) {
    compact = page.height < compactHeight;
    immersive = compact && page.width > page.height;
    if (immersive) {
      tableSize = TableLayout.fit(page);
      tableRect = Rect.fromCenter(
        center: page.center(Offset.zero),
        width: tableSize.width,
        height: tableSize.height,
      );
      // 浮层与球台同宽对齐，宽窗口下不会飘到球台两侧的留白里。
      final width = math.min(contentWidth, tableSize.width);
      header = Rect.fromLTWH((page.width - width) / 2, pagePadding, width, compactHeaderHeight);
      final dockWidth = math.min(width, dockMaxWidth);
      final dockHeight = singleRow ? immersiveDockHeight : dockStackCompactHeight;
      dock = Rect.fromLTWH(
        (page.width - dockWidth) / 2,
        page.height - pagePadding - dockHeight,
        dockWidth,
        dockHeight,
      );
      info = null;
      panel = _panelRect(header.bottom + gap, dock.top - gap);
      return;
    }
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
    tableSize = TableLayout.fit(core.size);
    // 球台放在页面正中，与浮层冲突时才回落到可用区域内。
    tableRect = _clamp(
      Rect.fromCenter(
        center: Offset(page.width / 2, page.height / 2),
        width: tableSize.width,
        height: tableSize.height,
      ),
      core,
    );
    info = _infoRect(core);
    panel = _panelRect(header.bottom + gap, dock.top - gap);
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

  /// 沉浸布局下叠在球台底部的操作条高度与最大宽度。
  static const double immersiveDockHeight = 48;
  static const double dockMaxWidth = 720;

  /// 信息条内联球组与提示的最小宽度。
  static const double inlineWidth = 800;

  /// 力度控制单行排布的最小宽度。
  static const double singleRowWidth = 560;

  /// 紧凑模式下力度控制单行排布的最小宽度。
  static const double compactSingleRowWidth = 480;

  /// 低于此高度视为矮屏，切换紧凑布局。
  static const double compactHeight = 560;

  final Size page;

  /// 矮屏紧凑布局：顶部条与操作条压缩，提示内联到顶部条。
  late final bool compact;

  /// 横屏沉浸布局：球台吃满整页，顶部条与操作条半透明叠在球台上。
  late final bool immersive;
  late final Rect header;
  late final Rect dock;
  late final Rect tableRect;
  late final Size tableSize;

  /// 可收起的球局浮层区域，叠在球台上方。
  late final Rect panel;

  /// 悬浮在球台上方的提示条；紧凑模式、宽屏内联与空间不足时为空。
  late final Rect? info;

  double get contentWidth => math.max(0.0, page.width - pagePadding * 2);

  bool get inline => page.width >= inlineWidth;

  bool get singleRow => page.width >= (compact ? compactSingleRowWidth : singleRowWidth);

  /// 横屏相对竖屏能给球台带来的面积倍数，用于判断是否需要自动横屏。
  static double landscapeGain(Size page) {
    final portrait = GameLayout(page).tableSize;
    final landscape = GameLayout(Size(page.height, page.width)).tableSize;
    final base = portrait.width * portrait.height;
    if (base <= 0) return 1;
    return landscape.width * landscape.height / base;
  }

  Rect _clamp(Rect rect, Rect bounds) {
    final maxLeft = math.max(bounds.left, bounds.right - rect.width);
    final maxTop = math.max(bounds.top, bounds.bottom - rect.height);
    return Rect.fromLTWH(
      math.min(math.max(rect.left, bounds.left), maxLeft),
      math.min(math.max(rect.top, bounds.top), maxTop),
      rect.width,
      rect.height,
    );
  }

  /// 球局浮层贴在右侧，宽度上限 320，高度夹在顶部条与操作条之间。
  Rect _panelRect(double top, double bottom) {
    final width = math.max(0.0, math.min(panelMaxWidth, page.width - pagePadding * 2 - 24));
    final left = math.max(pagePadding, page.width - pagePadding - width);
    return Rect.fromLTRB(
      left,
      top,
      math.max(left, page.width - pagePadding),
      math.max(top, bottom),
    );
  }

  /// 提示条贴在球台上沿，不占用球台空间；上方放不下时交给顶部条内联。
  Rect? _infoRect(Rect core) {
    if (inline || compact) return null;
    if (tableRect.top - core.top < infoHeight + gap) return null;
    final width = math.min(core.width, 640.0);
    return Rect.fromLTWH(
      core.center.dx - width / 2,
      tableRect.top - gap - infoHeight,
      width,
      infoHeight,
    );
  }
}
