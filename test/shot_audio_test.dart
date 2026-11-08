import 'package:chinese_eight_ball/core/physics.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/flame/shot_audio.dart';
import 'package:chinese_eight_ball/services/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';

const BallPocketed _pocketed = BallPocketed(ballId: 3, pocketIndex: 1, position: Vec2.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SoundFeedback> played;

  setUp(() {
    SoundService.reset();
    SoundService.configure(sound: true, haptics: false);
    played = [];
    SoundService.sink = (feedback, volume) => played.add(feedback);
  });

  tearDown(SoundService.reset);

  test('出杆与落袋各自发声', () {
    ShotAudio()
      ..strike()
      ..drain(const [_pocketed], 1 / 60);

    expect(played, [SoundFeedback.strike, SoundFeedback.pocket]);
  });

  test('同一帧的连续撞击按最短间隔节流', () {
    final audio = ShotAudio();

    audio.drain(const [
      BallImpact(strength: 2, ballBall: true),
      BallImpact(strength: 2, ballBall: true),
    ], 1 / 60);
    expect(played, [SoundFeedback.impact]);

    audio.drain(const [BallImpact(strength: 2, ballBall: true)], ShotAudio.impactGap);
    expect(played, [SoundFeedback.impact, SoundFeedback.impact]);
  });

  test('撞击音量随力度缩放并限幅', () {
    final volumes = <double>[];
    SoundService.sink = (feedback, volume) => volumes.add(volume);

    for (final strength in [0.1, 1.6, 9.0]) {
      ShotAudio().drain([BallImpact(strength: strength, ballBall: true)], 1);
    }

    expect(volumes, [0.12, 0.5, 0.85]);
  });

  test('关闭音效后不再发声', () {
    SoundService.configure(sound: false, haptics: false);

    ShotAudio()
      ..strike()
      ..drain(const [_pocketed], 1 / 60);

    expect(played, isEmpty);
  });
}
