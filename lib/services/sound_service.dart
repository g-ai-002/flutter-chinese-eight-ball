import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'log_service.dart';
import 'tone_synth.dart';

/// 台球音效：出杆、撞击、落袋、犯规与终局。
enum SoundFeedback { strike, impact, pocket, foul, win, lose }

/// 音效与触感反馈。
///
/// 所有 WAV 在运行时合成，仓库与安装包都不携带音频文件；合成结果交给
/// flutter_soloud 的内存音源播放，Android、Windows 与 Web 共用一套实现。
class SoundService {
  SoundService._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// 测试注入的音频出口，非空时不再触碰平台播放器。
  @visibleForTesting
  static void Function(SoundFeedback feedback, double volume)? sink;

  static final Map<SoundFeedback, AudioSource> _sources = {};
  static final Map<SoundFeedback, Uint8List> _clips = {};
  static Future<void>? _loading;
  static bool _loadFailed = false;

  static const Map<SoundFeedback, List<SynthNote>> _presets = {
    // 皮头击球：高频短促瞬态，混一点杆头摩擦噪声。
    SoundFeedback.strike: [
      SynthNote(frequency: 1240, start: 0, duration: 0.045, noise: 0.35),
      SynthNote(frequency: 640, start: 0.003, duration: 0.07, gain: 0.3, noise: 0.12),
    ],
    // 球撞球：清脆的树脂撞击声。
    SoundFeedback.impact: [
      SynthNote(frequency: 1560, start: 0, duration: 0.028, gain: 0.4, noise: 0.55),
      SynthNote(frequency: 920, start: 0.002, duration: 0.05, gain: 0.34, noise: 0.3),
    ],
    // 落袋：球体坠入袋兜的低沉回响。
    SoundFeedback.pocket: [
      SynthNote(frequency: 430, start: 0, duration: 0.08, gain: 0.35, noise: 0.5),
      SynthNote(frequency: 215, start: 0.03, duration: 0.18, gain: 0.6, noise: 0.22),
      SynthNote(frequency: 128, start: 0.06, duration: 0.24),
    ],
    // 犯规：两段下行提示。
    SoundFeedback.foul: [
      SynthNote(frequency: 392, start: 0, duration: 0.12, gain: 0.4),
      SynthNote(frequency: 294, start: 0.12, duration: 0.2, gain: 0.4),
    ],
    SoundFeedback.win: [
      SynthNote(frequency: 523.25, start: 0, duration: 0.16),
      SynthNote(frequency: 659.25, start: 0.12, duration: 0.16),
      SynthNote(frequency: 783.99, start: 0.24, duration: 0.2),
      SynthNote(frequency: 1046.5, start: 0.36, duration: 0.34, gain: 0.55),
    ],
    SoundFeedback.lose: [
      SynthNote(frequency: 440, start: 0, duration: 0.18, gain: 0.45),
      SynthNote(frequency: 349.23, start: 0.16, duration: 0.2, gain: 0.45),
      SynthNote(frequency: 261.63, start: 0.34, duration: 0.36),
    ],
  };

  static void configure({required bool sound, required bool haptics}) {
    soundEnabled = sound;
    hapticsEnabled = haptics;
  }

  static Future<void> init() => _ensureLoaded();

  static Future<void> _ensureLoaded() {
    if (_loadFailed || _sources.isNotEmpty) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) await soloud.init();
      for (final feedback in SoundFeedback.values) {
        _sources[feedback] = await soloud.loadMem(
          'eightball-${feedback.name}.wav',
          clipOf(feedback),
        );
      }
    } catch (error) {
      _loadFailed = true;
      _disposeAll();
      debugPrint('[SoundService] 音效初始化失败，已静音: $error');
      LogService.warning('音效初始化失败，已静音: $error');
    }
  }

  /// 某个反馈对应的合成音频，供测试校验音效配方。
  @visibleForTesting
  static Uint8List clipOf(SoundFeedback feedback) =>
      _clips.putIfAbsent(feedback, () => synthesizeWav(_presets[feedback]!));

  static void tap() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
  }

  static void play(SoundFeedback feedback, {double volume = 1.0}) {
    final level = volume.clamp(0.0, 1.0);
    if (soundEnabled) {
      final target = sink;
      if (target != null) {
        target(feedback, level);
      } else {
        unawaited(_play(feedback, level));
      }
    }
    // 撞击声一杆内会出现多次，只给关键节点震动，避免连续震动。
    if (!hapticsEnabled || feedback == SoundFeedback.impact) return;
    final haptic = switch (feedback) {
      SoundFeedback.strike => HapticFeedback.selectionClick,
      SoundFeedback.pocket => HapticFeedback.mediumImpact,
      SoundFeedback.foul => HapticFeedback.heavyImpact,
      SoundFeedback.win || SoundFeedback.lose => HapticFeedback.vibrate,
      SoundFeedback.impact => HapticFeedback.lightImpact,
    };
    haptic();
  }

  static Future<void> _play(SoundFeedback feedback, double volume) async {
    try {
      await _ensureLoaded();
      final source = _sources[feedback];
      if (source == null) return;
      final soloud = SoLoud.instance;
      soloud.stopAudioSource(source);
      soloud.play(source, volume: volume);
    } catch (error) {
      debugPrint('[SoundService] 播放失败: $error');
    }
  }

  static void _disposeAll() {
    final sources = _sources.values.toList();
    _sources.clear();
    for (final source in sources) {
      unawaited(_dispose(source));
    }
  }

  static Future<void> _dispose(AudioSource source) async {
    try {
      await SoLoud.instance.disposeSource(source);
    } catch (_) {
      // 音源已失效时无需再处理。
    }
  }

  @visibleForTesting
  static void reset() {
    sink = null;
    _disposeAll();
    _clips.clear();
    _loading = null;
    _loadFailed = false;
    soundEnabled = true;
    hapticsEnabled = true;
  }
}
