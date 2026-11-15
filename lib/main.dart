import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/startup.dart';
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

  // 偏好读取与桌面窗口互不依赖，并行执行，缩短启动关键路径。
  final storageFuture = StorageService.instance;
  await setupDesktopWindow();
  final storage = await storageFuture;

  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');
  MusicService.enabled = storage.musicEnabled;

  // 日志落盘与音频引擎初始化都挪到首帧之后：启动只等窗口与偏好，
  // 首帧不再为目录扫描、WAV 合成与平台音频初始化让路。
  runAfterFirstFrame(() async {
    await initLogging();
    await SoundService.init();
  });
  if (storage.musicEnabled && !kIsWeb) MusicService.startAfterFirstFrame();

  runApp(EightBallApp(storage: storage));
}
