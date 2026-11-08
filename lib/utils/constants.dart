/// Web 端字体：CanvasKit 没有系统中文字体回退，使用 soup_fonts 的思源黑体。
const String kWebFontFamily = 'SourceHanSansCN';

/// 桌面端优先使用的中文字体。
const String kDesktopFontFamily = 'Microsoft YaHei UI';

class AppConstants {
  AppConstants._();

  static const String appName = '中式黑八';
  static const String appNameEn = 'CHINESE EIGHT BALL';
  static const String version = '0.7.7';
  static const String appDirName = 'FlutterChineseEightBall';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeyDifficulty = 'difficulty';
  static const String prefKeyAiStrength = 'ai_strength';
  static const String prefKeyHumanSide = 'human_side';
  static const String prefKeyShowAimGuide = 'show_aim_guide';
  static const String prefKeyTableSkin = 'table_skin';
  static const String prefKeySound = 'sound_enabled';
  static const String prefKeyMusic = 'music_enabled';
  static const String prefKeyHaptics = 'haptics_enabled';
  static const String prefKeyMatchHistory = 'match_history';
  static const String prefKeyLogicRate = 'logic_rate';

  /// 最近击球记录保留条数（界面侧栏展示）。
  static const int maxVisibleLog = 6;
}
