import 'package:chinese_eight_ball/core/frame_idle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('渲染空闲判定', () {
    test('动态内容持续存在时不会挂起', () {
      final idle = FrameIdle();
      for (var i = 0; i < 100; i++) {
        expect(idle.tick(true, 1 / 60), isFalse);
      }
    });

    test('连续空闲超过阈值后建议挂起', () {
      final idle = FrameIdle(timeout: 0.35);
      var paused = false;
      for (var i = 0; i < 18; i++) {
        paused = idle.tick(false, 1 / 60);
      }
      expect(paused, isFalse, reason: '0.35 秒之前仍在计时');

      for (var i = 0; i < 3; i++) {
        paused = idle.tick(false, 1 / 60);
      }
      expect(paused, isTrue);
    });

    test('一次交互会重新开始计时', () {
      final idle = FrameIdle(timeout: 0.3);
      for (var i = 0; i < 17; i++) {
        idle.tick(false, 1 / 60);
      }
      idle.markActive();
      expect(idle.tick(false, 1 / 60), isFalse);
      for (var i = 0; i < 16; i++) {
        expect(idle.tick(false, 1 / 60), isFalse);
      }
    });

    test('画面重新出现动态内容时计时归零', () {
      final idle = FrameIdle(timeout: 0.2);
      for (var i = 0; i < 11; i++) {
        idle.tick(false, 1 / 60);
      }
      expect(idle.tick(true, 1 / 60), isFalse);
      expect(idle.tick(false, 1 / 60), isFalse);
    });

    test('缺少时间增量时按 60Hz 估算', () {
      final idle = FrameIdle(timeout: 0.1);
      expect(idle.tick(false, 0), isFalse);
      expect(idle.tick(false, 0), isFalse);
      expect(idle.tick(false, 0), isFalse);
      expect(idle.tick(false, 0), isFalse);
      expect(idle.tick(false, 0), isFalse);
      expect(idle.tick(false, 0), isFalse);
      expect(idle.tick(false, 0), isTrue);
    });
  });
}
