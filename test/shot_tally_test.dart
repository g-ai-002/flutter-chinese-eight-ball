import 'package:chinese_eight_ball/core/shot_tally.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/record_factory.dart';

void main() {
  test('进球率在零杆时返回零，否则按杆数平均', () {
    expect(potRateOf(0, 3), 0);
    expect(potRateOf(4, 3), closeTo(0.75, 1e-9));
  });

  test('记录级杆数与进球数不展开逐杆统计', () {
    final record = testRecord(
      index: 0,
      shots: [
        (0, [1, 2]),
        (1, [0]),
        (0, []),
      ],
    );

    expect(record.shotCount, 3);
    expect(record.pottedTargets, 2);
  });

  test('空记录返回零值', () {
    final tally = ShotTally.of(const []);
    expect(tally.shots, 0);
    expect(tally.potted, 0);
    expect(tally.bestShotPotted, 0);
    expect(tally.bestStreak, 0);
  });

  test('累计杆数与本方进球，母球落袋不计入', () {
    final tally = ShotTally.of([
      testRecord(
        index: 0,
        shots: [
          (0, [1]),
          (0, [0, 2, 3]),
          (1, [0]),
        ],
      ),
      testRecord(
        index: 1,
        mode: 'twoPlayers',
        shots: [
          (1, [9]),
        ],
      ),
    ]);

    expect(tally.shots, 4);
    expect(tally.potted, 4);
    expect(tally.bestShotPotted, 2);
  });

  test('连续进球按球手切换或空杆中断', () {
    final tally = ShotTally.of([
      testRecord(
        index: 0,
        shots: [
          (0, [1]),
          (0, [2]),
          (1, [9]),
          (1, []),
          (1, [10]),
          (1, [11]),
          (1, [12]),
        ],
      ),
    ]);

    expect(tally.bestStreak, 3);
  });

  test('连续进球不跨对局累加', () {
    final tally = ShotTally.of([
      testRecord(
        index: 0,
        shots: [
          (0, [1]),
        ],
      ),
      testRecord(
        index: 1,
        shots: [
          (0, [2]),
        ],
      ),
    ]);

    expect(tally.bestStreak, 1);
    expect(tally.bestShotPotted, 1);
  });
}
