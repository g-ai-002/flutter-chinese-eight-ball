import 'package:chinese_eight_ball/services/music_service.dart';
import 'package:chinese_eight_ball/services/tone_synth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('背景音乐等首帧渲染后才开始', (tester) async {
    MusicService.reset();
    final played = <bool>[];
    MusicService.sink = (enabled) => played.add(enabled);

    MusicService.startAfterFirstFrame();
    expect(played, isEmpty, reason: '合成与播放不能占用启动首帧');

    tester.binding.scheduleFrame();
    await tester.pump();
    expect(played, [true]);

    MusicService.reset();
  });

  test('后台合成入口产出与直接合成一致的 WAV', () {
    final clip = synthesizeMusicWavBackground(kMusicSampleRate);
    final direct = synthesizeMusicWav();

    expect(String.fromCharCodes(clip.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(clip.sublist(8, 12)), 'WAVE');
    expect(clip.length, direct.length);
    expect(clip.sublist(0, 64), direct.sublist(0, 64));
  });

  testWidgets('背景音乐能在后台 isolate 合成', (tester) async {
    final clip = await tester.runAsync(
      () => compute(synthesizeMusicWavBackground, kMusicSampleRate),
    );

    expect(clip, isNotNull);
    expect(String.fromCharCodes(clip!.sublist(0, 4)), 'RIFF');
    expect(clip.length, synthesizeMusicWav().length);
  });
}
