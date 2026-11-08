import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'game_layout.dart';

/// 球台页面的屏幕方向策略。
enum TableOrientationPolicy { followSystem, portrait, landscape }

/// 球台是约 1.87:1 的横向网格：手机等窄屏竖握时球台被两侧留白压得很小，
/// 横屏能明显放大球台，因此窄屏上自动进入横屏全屏；平板与桌面窗口保持
/// 系统方向。离开球台页面后恢复系统方向与状态栏，不残留全屏状态。
class TableOrientation {
  TableOrientation._();

  /// 手机与折叠屏折叠态的短边上限（逻辑像素）。
  static const double narrowSide = 600;

  /// 横屏球台面积至少放大到竖屏的 1.25 倍才值得旋转。
  static const double minGain = 1.25;

  static int _consumers = 0;
  static TableOrientationPolicy? _applied;

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 球台页面进入时登记；最后一个页面离开时才恢复系统方向。
  static void attach() => _consumers++;

  static void detach() {
    _consumers = math.max(0, _consumers - 1);
    if (_consumers == 0) restore();
  }

  /// 窄屏上横屏能显著放大球台就自动横屏，否则保持竖屏；大屏交给系统。
  static TableOrientationPolicy policyFor(Size page) {
    final narrow = math.min(page.width, page.height) <= narrowSide;
    if (!narrow) return TableOrientationPolicy.followSystem;
    if (page.width > page.height) return TableOrientationPolicy.landscape;
    return GameLayout.landscapeGain(page) >= minGain
        ? TableOrientationPolicy.landscape
        : TableOrientationPolicy.portrait;
  }

  /// 按页面尺寸应用方向策略；同一策略只下发一次，避免重复调用平台通道。
  static void sync(Size page) {
    if (!_supported || _consumers == 0) return;
    final policy = policyFor(page);
    if (policy == _applied) return;
    _applied = policy;
    switch (policy) {
      case TableOrientationPolicy.landscape:
        unawaited(
          SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]),
        );
        unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
      case TableOrientationPolicy.portrait:
        unawaited(
          SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]),
        );
        _resetChrome(keepOrientation: true);
      case TableOrientationPolicy.followSystem:
        _resetChrome();
    }
  }

  /// 球台页面全部关闭后恢复系统方向与状态栏。
  static void restore() {
    _applied = null;
    if (!_supported) return;
    _resetChrome();
  }

  static void _resetChrome({bool keepOrientation = false}) {
    if (!keepOrientation) {
      unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    }
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  @visibleForTesting
  static void resetForTests() {
    _consumers = 0;
    _applied = null;
  }
}
