import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService.error('Flutter 异常', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService.error('未捕获异常', error, stack);
    return true;
  };

  await setupDesktopWindow();
  await initLogging();

  final storage = await StorageService.instance;
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');
  unawaited(SoundService.init());
  MusicService.enabled = storage.musicEnabled;
  // 背景音乐合成较重，等首帧渲染后再在后台 isolate 合成，启动画面不再卡顿。
  if (storage.musicEnabled && !kIsWeb) MusicService.startAfterFirstFrame();

  runApp(EightBallApp(storage: storage));
}
