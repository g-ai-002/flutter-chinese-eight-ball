import 'package:shared_preferences/shared_preferences.dart';

import '../core/ai.dart';
import '../utils/constants.dart';

/// 轻量偏好存储：写入失败时静默忽略，不影响对局主流程。
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
    return service;
  }

  /// 仅供测试：清空单例，配合 SharedPreferences 的 mock 数据使用。
  static void resetForTests() => _instance = null;

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService 尚未初始化');
    return prefs;
  }

  Future<void> _write(Future<bool> Function(SharedPreferences prefs) action) async {
    try {
      await action(_p);
    } catch (_) {}
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyDarkMode, value));

  bool get showAimGuide => _p.getBool(AppConstants.prefKeyShowAimGuide) ?? true;
  Future<void> setShowAimGuide(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyShowAimGuide, value));

  /// 球台配色 id，未设置或未知值由 `tableSkinOf` 回退到默认皮肤。
  String? get tableSkinId => _p.getString(AppConstants.prefKeyTableSkin);
  Future<void> setTableSkinId(String value) =>
      _write((p) => p.setString(AppConstants.prefKeyTableSkin, value));

  bool get soundEnabled => _p.getBool(AppConstants.prefKeySound) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeySound, value));

  bool get musicEnabled => _p.getBool(AppConstants.prefKeyMusic) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyMusic, value));

  bool get hapticsEnabled => _p.getBool(AppConstants.prefKeyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyHaptics, value));

  /// AI 难度，未设置或未知值回退到进阶。
  AiDifficulty get difficulty => AiDifficulty.stored(_p.getString(AppConstants.prefKeyDifficulty));

  Future<void> setDifficulty(AiDifficulty value) =>
      _write((p) => p.setString(AppConstants.prefKeyDifficulty, value.name));

  /// 自定义 AI 强度，0~1，默认中等。
  double get aiStrength =>
      (_p.getDouble(AppConstants.prefKeyAiStrength) ?? 0.5).clamp(0.0, 1.0).toDouble();

  Future<void> setAiStrength(double value) =>
      _write((p) => p.setDouble(AppConstants.prefKeyAiStrength, value));

  /// 人类开球方：0 先手，1 后手。
  int get humanSide => _p.getInt(AppConstants.prefKeyHumanSide) ?? 0;
  Future<void> setHumanSide(int value) =>
      _write((p) => p.setInt(AppConstants.prefKeyHumanSide, value));

  /// 最近对局记录的 JSON，解析与裁剪由 `MatchHistory` 负责。
  String? get matchHistoryJson => _p.getString(AppConstants.prefKeyMatchHistory);
  Future<void> setMatchHistoryJson(String value) =>
      _write((p) => p.setString(AppConstants.prefKeyMatchHistory, value));
}
