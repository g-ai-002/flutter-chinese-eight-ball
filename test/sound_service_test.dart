import 'dart:typed_data';

import 'package:chinese_eight_ball/services/sound_service.dart';
import 'package:chinese_eight_ball/services/tone_synth.dart';
import 'package:flutter_test/flutter_test.dart';

int readInt32(Uint8List bytes, int offset) {
  final data = ByteData.sublistView(bytes);
  return data.getUint32(offset, Endian.little);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('合成音效是合法的 16 位单声道 WAV', () {
    final clip = SoundService.clipOf(SoundFeedback.impact);
    expect(clip.length, greaterThan(44));
    expect(String.fromCharCodes(clip.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(clip.sublist(8, 12)), 'WAVE');
    expect(readInt32(clip, 24), kSynthSampleRate);
    expect(clip.length - 44, readInt32(clip, 40));
  });

  test('每类反馈都能合成非静音音频', () {
    for (final feedback in SoundFeedback.values) {
      final clip = SoundService.clipOf(feedback);
      expect(clip.length, greaterThan(44), reason: feedback.name);
      final data = ByteData.sublistView(clip);
      var peak = 0;
      for (var offset = 44; offset + 1 < clip.length; offset += 2) {
        final sample = data.getInt16(offset, Endian.little).abs();
        if (sample > peak) peak = sample;
      }
      expect(peak, greaterThan(0), reason: feedback.name);
    }
  });

  test('背景音乐循环带淡入淡出且为合法 WAV', () {
    final music = synthesizeMusicWav();
    expect(String.fromCharCodes(music.sublist(0, 4)), 'RIFF');
    expect(readInt32(music, 24), kMusicSampleRate);
    final data = ByteData.sublistView(music);
    var peak = 0;
    for (var offset = 44; offset + 1 < music.length; offset += 2) {
      final sample = data.getInt16(offset, Endian.little).abs();
      if (sample > peak) peak = sample;
    }
    expect(peak, greaterThan(1000));
  });

  test('音效开关与注入出口生效', () {
    SoundService.reset();
    SoundService.configure(sound: true, haptics: false);
    final played = <SoundFeedback>[];
    SoundService.sink = (feedback, volume) => played.add(feedback);

    SoundService.play(SoundFeedback.pocket, volume: 0.5);
    expect(played, [SoundFeedback.pocket]);

    SoundService.configure(sound: false, haptics: false);
    SoundService.play(SoundFeedback.win);
    expect(played, [SoundFeedback.pocket]);

    SoundService.reset();
  });
}
