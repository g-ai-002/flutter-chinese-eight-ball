import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/match_controller.dart';
import 'package:chinese_eight_ball/core/match_history.dart';
import 'package:chinese_eight_ball/core/match_record.dart';
import 'package:chinese_eight_ball/core/match_recorder.dart';
import 'package:chinese_eight_ball/core/replay_player.dart';
import 'package:chinese_eight_ball/core/table_geometry.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:chinese_eight_ball/services/match_history_service.dart';
import 'package:chinese_eight_ball/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/record_factory.dart';

void runToRest(MatchController controller, {int maxTicks = 4000}) {
  var ticks = 0;
  while (controller.phase == MatchPhase.shooting && ticks < maxTicks) {
    controller.tick(1 / 60);
    ticks++;
  }
}

/// 构造「玩家 0 已清台、黑八与母球正对右上角袋」的终局前状态。
MatchController prepareWinningShot({GameMode mode = GameMode.twoPlayers}) {
  final controller = MatchController(mode: mode, autoPlayAi: false);
  final rules = controller.rules;
  rules
    ..isBreak = false
    ..tableOpen = false
    ..current = 0;
  rules.groups[0] = PlayerGroup.solids;
  rules.groups[1] = PlayerGroup.stripes;
  for (final ball in controller.balls) {
    if (ball.kind == BallKind.solid) ball.active = false;
    if (ball.isCue) ball.position = const Vec2(2.18, 0.36);
    if (ball.isEight) ball.position = const Vec2(2.46, 0.08);
  }
  controller
    ..setAimAngle(angleOf(const Vec2(2.18, 0.36), const Vec2(2.46, 0.08)))
    ..setPower(0.6);
  return controller;
}

MatchController finishWinningShot() {
  final controller = prepareWinningShot();
  controller
    ..setCalledPocket(2)
    ..shoot();
  runToRest(controller);
  return controller;
}

MatchRecord sampleRecord({int index = 0, int shotCount = 1}) {
  final balls = TableGeometry.rackBalls();
  final cue = balls.firstWhere((ball) => ball.isCue);
  return MatchRecord(
    id: 'record-$index',
    createdAt: DateTime(2026, 11, 5, 20).add(Duration(minutes: index)),
    mode: 'vsAi',
    modeLabel: '人机对战',
    difficultyLabel: '进阶',
    humanSide: 0,
    winner: 0,
    winnerName: '玩家',
    title: '你赢了',
    playerWin: true,
    endReason: '清台后打进黑八',
    shots: [
      for (var i = 0; i < shotCount; i++)
        ReplayShot(
          player: 0,
          balls: balls,
          angle: angleOf(cue.position, TableGeometry.footSpot),
          power: 0.8,
          calledPocket: null,
          result: '开球',
          potted: const [],
        ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('对局记录', () {
    test('终局后生成逐杆记录并保存击球参数', () {
      final controller = finishWinningShot();
      addTearDown(controller.dispose);

      expect(controller.phase, MatchPhase.gameOver);
      final record = controller.finishedRecord;
      expect(record, isNotNull);
      expect(record!.shots, hasLength(1));
      expect(record.winner, 0);
      expect(record.title, '玩家一获胜');
      expect(record.endReason, contains('黑八'));
      expect(record.modeLabel, '双人对战');

      final shot = record.shots.single;
      expect(shot.player, 0);
      expect(shot.calledPocket, 2);
      expect(shot.power, closeTo(0.6, 1e-9));
      expect(shot.potted, contains(8));
      expect(
        shot.balls.firstWhere((ball) => ball.isEight).position,
        const Vec2(2.46, 0.08),
      );
    });

    test('练习模式不生成对局记录，重新开球会清空记录', () {
      final controller = MatchController(
        mode: GameMode.practice,
        autoPlayAi: false,
      );
      addTearDown(controller.dispose);
      controller
        ..setPower(0.5)
        ..shoot();
      runToRest(controller);
      expect(controller.finishedRecord, isNull);

      final match = finishWinningShot();
      addTearDown(match.dispose);
      expect(match.finishedRecord, isNotNull);
      match.restart();
      expect(match.finishedRecord, isNull);
    });

    test('单场录制超过上限后不再累积杆次', () {
      final recorder = MatchRecorder(
        mode: 'twoPlayers',
        modeLabel: '双人对战',
        difficultyLabel: '进阶',
        humanSide: 0,
      );
      final balls = TableGeometry.rackBalls();
      for (var i = 0; i < MatchRecorder.maxShots + 3; i++) {
        recorder.beginShot(player: 0, balls: balls, angle: 0, power: 0.5);
        recorder.endShot(result: '第 $i 杆', potted: const []);
      }

      expect(recorder.shotCount, MatchRecorder.maxShots);
      final record = recorder.finish(
        winner: 0,
        winnerName: '玩家一',
        title: '玩家一获胜',
        playerWin: true,
        reason: '测试',
      );
      expect(record, isNotNull);
      expect(record!.shotCount, MatchRecorder.maxShots);
      expect(record.shots.last.result, '第 ${MatchRecorder.maxShots - 1} 杆');
    });

    test('记录 JSON 往返保留球局、结果与参数', () {
      final record = sampleRecord();
      final decoded = MatchRecord.fromJson(record.toJson());

      expect(decoded, isNotNull);
      expect(decoded!.id, record.id);
      expect(decoded.title, record.title);
      expect(decoded.shotCount, 1);
      final shot = decoded.shots.single;
      expect(shot.result, '开球');
      expect(shot.power, closeTo(0.8, 1e-9));
      expect(shot.balls, hasLength(record.shots.single.balls.length));
      expect(
        shot.balls.firstWhere((ball) => ball.isCue).position.x,
        closeTo(TableGeometry.headSpot.x, 1e-3),
      );
    });

    test('历史记录按时间倒序并只保留最近 10 场', () {
      final records = [for (var i = 0; i < 12; i++) sampleRecord(index: i)];
      final decoded = MatchHistory.decode(MatchHistory.encode(records));

      expect(decoded, hasLength(MatchHistory.maxRecords));
      expect(decoded.first.id, 'record-11');
      expect(decoded.last.id, 'record-2');
    });

    test('排序与导出摘要使用同一口径', () {
      final older = sampleRecord();
      final newer = sampleRecord(index: 2);

      expect(newestFirst([older, newer]).map((record) => record.id), [
        'record-2',
        'record-0',
      ]);
      expect(newer.resultSummary, '人机对战 · 进阶 · 你赢了 · 1 杆 · 0 球 · 清台后打进黑八');

      final versus = testRecord(
        index: 3,
        mode: 'twoPlayers',
        shots: const [
          (0, [1, 2]),
        ],
      );
      expect(versus.resultSummary, '双人对战 · 你赢了 · 1 杆 · 2 球 · 清台后打进黑八');
    });

    test('损坏的历史数据被安全丢弃', () {
      expect(MatchHistory.decode(null), isEmpty);
      expect(MatchHistory.decode('not-json'), isEmpty);
      expect(MatchHistory.decode('{"a":1}'), isEmpty);
      expect(MatchHistory.decode('[{"id":"x"},42]'), isEmpty);
    });
  });

  group('回放播放器', () {
    test('按记录重演最后一杆并停在终局', () {
      final controller = finishWinningShot();
      addTearDown(controller.dispose);
      final record = controller.finishedRecord!;
      final player = ReplayPlayer(record);

      expect(player.total, 1);
      expect(player.index, 0);
      // 清台前已打掉 7 颗全色球，台面剩母球、黑八与 7 颗花色球。
      expect(player.balls.where((ball) => ball.active), hasLength(9));

      player.play();
      expect(player.isPlaying, isTrue);
      var ticks = 0;
      while (!player.atEnd && ticks < 900) {
        player.tick(1 / 60);
        ticks++;
      }

      expect(player.atEnd, isTrue);
      expect(player.isPlaying, isFalse);
      expect(player.progress, 1);
      expect(
        player.balls.where((ball) => ball.active).map((ball) => ball.id),
        isNot(contains(8)),
      );
    });

    test('逐杆跳转会重建对应球局并暂停', () {
      final record = sampleRecord();
      final player = ReplayPlayer(record);
      player.play();
      expect(player.isPlaying, isTrue);

      player.seek(1);
      expect(player.atEnd, isTrue);
      expect(player.isPlaying, isFalse);
      expect(player.displayIndex, 1);

      player.seek(0);
      expect(player.atEnd, isFalse);
      expect(player.displayIndex, 1);
      expect(player.balls.where((ball) => ball.active), hasLength(16));
    });

    test('暂停后继续播放接着当前杆推进，不重演', () {
      final record = sampleRecord();
      final player = ReplayPlayer(record);
      player.play();
      for (var i = 0; i < 3; i++) {
        player.tick(1 / 60);
      }
      final moving = player.balls.firstWhere((ball) => ball.isCue).position;

      player.pause();
      expect(player.isPlaying, isFalse);
      player.tick(1 / 60);
      expect(player.balls.firstWhere((ball) => ball.isCue).position, moving);

      player.play();
      player.tick(1 / 60);
      final resumed = player.balls.firstWhere((ball) => ball.isCue).position;
      expect(resumed, isNot(moving));
      expect(
        resumed.distanceTo(
          record.shots.first.balls.firstWhere((b) => b.isCue).position,
        ),
        greaterThan(0.01),
      );
    });

    test('seek 会取消播放在途状态并复原球局', () {
      final record = sampleRecord();
      final initial = record.shots.first.balls
          .firstWhere((b) => b.isCue)
          .position;
      final player = ReplayPlayer(record)..play();
      for (var i = 0; i < 3; i++) {
        player.tick(1 / 60);
      }

      player.seek(0);
      expect(player.isPlaying, isFalse);
      expect(player.balls.firstWhere((ball) => ball.isCue).position, initial);

      player.tick(1 / 60);
      expect(player.balls.firstWhere((ball) => ball.isCue).position, initial);
    });

    test('终局后重新播放从第一杆开始', () {
      final player = ReplayPlayer(sampleRecord());
      player.play();
      var ticks = 0;
      while (!player.atEnd && ticks < 900) {
        player.tick(1 / 60);
        ticks++;
      }
      expect(player.atEnd, isTrue);
      expect(player.isPlaying, isFalse);

      player.play();
      expect(player.index, 0);
      expect(player.displayIndex, 1);
      expect(player.isPlaying, isTrue);
    });

    test('空记录不崩溃且禁止播放', () {
      final record = sampleRecord();
      final empty = MatchRecord(
        id: 'empty',
        createdAt: record.createdAt,
        mode: record.mode,
        modeLabel: record.modeLabel,
        difficultyLabel: record.difficultyLabel,
        humanSide: record.humanSide,
        winner: record.winner,
        winnerName: record.winnerName,
        title: record.title,
        playerWin: record.playerWin,
        endReason: record.endReason,
        shots: const [],
      );
      final player = ReplayPlayer(empty);
      player.play();
      player.next();
      player.previous();
      player.tick(1 / 60);

      expect(player.canPlay, isFalse);
      expect(player.isPlaying, isFalse);
      expect(player.progress, 0);
    });
  });

  group('对局记录存储', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      StorageService.resetForTests();
    });

    test('写入、读取、删除与清空', () async {
      final service = MatchHistoryService.instance;
      expect(await service.load(), isEmpty);

      await service.add(sampleRecord());
      await service.add(sampleRecord(index: 1));
      var records = await service.load();
      expect(records, hasLength(2));
      expect(records.first.id, 'record-1');

      records = await service.remove('record-1');
      expect(records, hasLength(1));
      expect(records.single.id, 'record-0');

      await service.clear();
      expect(await service.load(), isEmpty);
    });

    test('超过上限时丢弃最旧的记录', () async {
      final service = MatchHistoryService.instance;
      for (var i = 0; i < MatchHistory.maxRecords + 2; i++) {
        await service.add(sampleRecord(index: i));
      }
      final records = await service.load();
      expect(records, hasLength(MatchHistory.maxRecords));
      expect(records.first.id, 'record-11');
      expect(records.any((record) => record.id == 'record-0'), isFalse);
    });
  });
}
