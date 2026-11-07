import 'package:chinese_eight_ball/core/logic_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('默认 60Hz，缺失或未知速率回退 60Hz', () {
    expect(LogicClock().rate, LogicRate.hz60);
    expect(LogicRate.hz30.hz, 30);
    expect(LogicRate.hz120.step, closeTo(1 / 120, 1e-12));
    expect(LogicRate.stored(null), LogicRate.hz60);
    expect(LogicRate.stored('hz120'), LogicRate.hz120);
    expect(LogicRate.stored('hz240'), LogicRate.hz60);
  });

  test('30Hz 每两步 60fps 帧推进一次逻辑', () {
    final clock = LogicClock()..rate = LogicRate.hz30;
    final steps = <double>[];

    expect(clock.advance(1 / 60, steps.add), 0);
    expect(clock.advance(1 / 60, steps.add), 1);
    expect(steps.single, closeTo(1 / 30, 1e-9));
    expect(clock.advance(1 / 30, steps.add), 1);
    expect(steps, hasLength(2));
  });

  test('120Hz 一帧 60fps 拆成两个逻辑步', () {
    final clock = LogicClock()..rate = LogicRate.hz120;
    final steps = <double>[];

    expect(clock.advance(1 / 60, steps.add), 2);
    expect(steps, hasLength(2));
    expect(steps.every((step) => (step - 1 / 120).abs() < 1e-12), isTrue);
  });

  test('单帧步数有上限且丢弃积压', () {
    final clock = LogicClock(maxStepsPerFrame: 3)..rate = LogicRate.hz30;
    var steps = 0;

    expect(clock.advance(1.0, (_) => steps++), 3);
    expect(steps, 3);
    expect(clock.advance(1 / 30, (_) => steps++), 1);
    expect(steps, 4);
  });

  test('静置时 reset 清空不足一步的余量', () {
    final clock = LogicClock();
    var steps = 0;

    clock.advance(1 / 100, (_) => steps++);
    expect(steps, 0);

    clock.reset();
    for (var i = 0; i < 3; i++) {
      clock.advance(1 / 200, (_) => steps++);
    }
    expect(steps, 0);
    expect(clock.advance(1 / 200, (_) => steps++), 1);
    expect(steps, 1);
  });
}
