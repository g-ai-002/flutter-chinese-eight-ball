import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/ai.dart';
import '../core/logic_clock.dart';
import '../services/music_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/table_skin.dart';

/// 用户偏好：主题、球台配色、AI 难度、开球先后与音效反馈。
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _syncFeedback();
  }

  final StorageService _storage;

  bool get darkMode => _storage.darkMode;
  Future<void> setDarkMode(bool value) => _update(() => _storage.setDarkMode(value));

  AiDifficulty get difficulty => _storage.difficulty;
  Future<void> setDifficulty(AiDifficulty value) => _update(() => _storage.setDifficulty(value));

  double get aiStrength => _storage.aiStrength;
  Future<void> setAiStrength(double value) => _update(() => _storage.setAiStrength(value));

  int get humanSide => _storage.humanSide;
  Future<void> setHumanSide(int value) => _update(() => _storage.setHumanSide(value));

  LogicRate get logicRate => _storage.logicRate;
  Future<void> setLogicRate(LogicRate value) => _update(() => _storage.setLogicRate(value));

  TableSkin get tableSkin => tableSkinOf(_storage.tableSkinId);
  Future<void> setTableSkin(TableSkin value) => _update(() => _storage.setTableSkinId(value.id));

  bool get showAimGuide => _storage.showAimGuide;
  Future<void> setShowAimGuide(bool value) => _update(() => _storage.setShowAimGuide(value));

  bool get soundEnabled => _storage.soundEnabled;
  Future<void> setSoundEnabled(bool value) => _update(() async {
    await _storage.setSoundEnabled(value);
    _syncFeedback();
  });

  bool get musicEnabled => _storage.musicEnabled;
  Future<void> setMusicEnabled(bool value) => _update(() async {
    await _storage.setMusicEnabled(value);
    unawaited(MusicService.setEnabled(value));
  });

  bool get hapticsEnabled => _storage.hapticsEnabled;
  Future<void> setHapticsEnabled(bool value) => _update(() async {
    await _storage.setHapticsEnabled(value);
    _syncFeedback();
  });

  void _syncFeedback() => SoundService.configure(sound: soundEnabled, haptics: hapticsEnabled);

  Future<void> _update(Future<void> Function() write) async {
    await write();
    notifyListeners();
  }
}
