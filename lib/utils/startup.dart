import 'dart:async';

import 'package:flutter/widgets.dart';

/// 把非首帧必需的任务推迟到首帧渲染之后执行。
///
/// 日志目录扫描、音频引擎初始化与 WAV 合成都会占用主线程，排在启动关键
/// 路径上会推迟第一帧；首帧之后的回调不影响启动观感，也不阻塞用户操作。
void runAfterFirstFrame(Future<void> Function() task) {
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(task()));
}
