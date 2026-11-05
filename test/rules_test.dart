import 'package:chinese_eight_ball/core/ball.dart';
import 'package:chinese_eight_ball/core/physics.dart';
import 'package:chinese_eight_ball/core/rules.dart';
import 'package:chinese_eight_ball/core/vec.dart';
import 'package:flutter_test/flutter_test.dart';

BallPocketed potted(int id, [int pocket = 0]) => BallPocketed(
  ballId: id,
  pocketIndex: pocket,
  position: const Vec2(0.1, 0.1),
);

ShotOutcome outcome({
  List<int> pottedIds = const [],
  int? firstContact = 1,
  bool cushionAfterContact = false,
}) => ShotOutcome(
  potted: [for (final id in pottedIds) potted(id)],
  firstContact: firstContact,
  cushionAfterContact: cushionAfterContact,
  timedOut: false,
);

void main() {
  group('开球', () {
    test('开球后球台开放并交换球权', () {
      final rules = MatchRules();
      final ruling = rules.apply(
        outcome(cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.foul, isFalse);
      expect(ruling.keepTurn, isFalse);
      expect(rules.tableOpen, isTrue);
      expect(rules.current, 1);
      expect(rules.isBreak, isFalse);
    });

    test('开球黑八落袋重新摆球，仍由原球手开球', () {
      final rules = MatchRules();
      final ruling = rules.apply(
        outcome(pottedIds: [8], cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.rerack, isTrue);
      expect(ruling.keepTurn, isTrue);
      expect(rules.current, 0);
      expect(rules.over, isFalse);
    });

    test('开球母球落袋判犯规并给对手自由球', () {
      final rules = MatchRules();
      final ruling = rules.apply(
        outcome(pottedIds: [0], cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, contains('母球'));
      expect(rules.current, 1);
      expect(rules.ballInHand, isTrue);
    });

    test('开球黑八与母球同时落袋仍然重新摆球', () {
      final rules = MatchRules();
      final ruling = rules.apply(
        outcome(pottedIds: [0, 8], cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.rerack, isTrue);
      expect(ruling.gameOver, isFalse);
      expect(rules.over, isFalse);
      expect(rules.current, 0);
    });
  });

  group('球组归属', () {
    test('首次合法进球确定双方球组并继续击球', () {
      final rules = MatchRules();
      rules.apply(outcome(cushionAfterContact: true), onEight: false);
      // 开球后换到球手 1，此处直接切回球手 0 模拟一次进攻。
      rules.current = 0;
      final ruling = rules.apply(
        outcome(pottedIds: [3], firstContact: 3),
        onEight: false,
      );
      expect(ruling.foul, isFalse);
      expect(ruling.keepTurn, isTrue);
      expect(rules.groups[0], PlayerGroup.solids);
      expect(rules.groups[1], PlayerGroup.stripes);
      expect(rules.tableOpen, isFalse);
    });

    test('开放球台同时落袋两种花色按首颗归属', () {
      final rules = MatchRules()..isBreak = false;
      final ruling = rules.apply(
        outcome(pottedIds: [10, 3], firstContact: 10),
        onEight: false,
      );
      expect(ruling.foul, isFalse);
      expect(rules.groups[0], PlayerGroup.stripes);
      expect(rules.groups[1], PlayerGroup.solids);
    });

    test('打进对方球且无本方进球交换球权', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [12], firstContact: 2),
        onEight: false,
      );
      expect(ruling.foul, isFalse);
      expect(ruling.keepTurn, isFalse);
      expect(rules.current, 1);
    });

    test('开放球台犯规时不进行球组归属', () {
      final rules = MatchRules()..isBreak = false;
      final ruling = rules.apply(
        outcome(pottedIds: [0, 3], firstContact: 3),
        onEight: false,
      );
      expect(ruling.foul, isTrue);
      expect(rules.tableOpen, isTrue);
      expect(rules.groups, [null, null]);
      expect(rules.current, 1);
    });
  });

  group('犯规', () {
    test('先碰对方球判犯规', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [9], firstContact: 9),
        onEight: false,
      );
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, contains('对方'));
      expect(rules.ballInHand, isTrue);
    });

    test('碰撞后无球碰库判犯规', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.tableOpen = false;
      final ruling = rules.apply(outcome(), onEight: false);
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, contains('碰库'));
    });

    test('碰撞后有球落袋则无需碰库', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [3], firstContact: 3),
        onEight: false,
      );
      expect(ruling.foul, isFalse);
      expect(ruling.keepTurn, isTrue);
    });

    test('母球落袋优先于其他犯规原因', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [0, 12], firstContact: 12),
        onEight: false,
      );
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, '母球落袋');
      expect(rules.ballInHand, isTrue);
    });

    test('空杆判犯规', () {
      final rules = MatchRules()..isBreak = false;
      final ruling = rules.apply(
        outcome(firstContact: null, cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, contains('空杆'));
    });

    test('开放球台先碰黑八判犯规', () {
      final rules = MatchRules()..isBreak = false;
      final ruling = rules.apply(
        outcome(firstContact: 8, cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, contains('黑八'));
    });

    test('清台后未先碰黑八判犯规', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(cushionAfterContact: true),
        onEight: true,
      );
      expect(ruling.foul, isTrue);
      expect(ruling.foulReason, contains('未先碰黑八'));
    });
  });

  group('黑八胜负', () {
    test('清台后打进指定袋口的黑八获胜', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [8], firstContact: 8),
        onEight: true,
        calledPocket: 0,
      );
      expect(ruling.gameOver, isTrue);
      expect(ruling.winner, 0);
      expect(rules.over, isTrue);
    });

    test('黑八落入非指定袋口判负', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [8], firstContact: 8),
        onEight: true,
        calledPocket: 2,
      );
      expect(ruling.gameOver, isTrue);
      expect(ruling.winner, 1);
      expect(rules.endReason, contains('非指定袋口'));
    });

    test('未指定袋口时黑八落袋判负', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [8], firstContact: 8),
        onEight: true,
      );
      expect(ruling.gameOver, isTrue);
      expect(ruling.winner, 1);
      expect(rules.endReason, contains('未指定袋口'));
    });

    test('提前打进黑八判负', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [8], firstContact: 8, cushionAfterContact: true),
        onEight: false,
      );
      expect(ruling.gameOver, isTrue);
      expect(ruling.winner, 1);
      expect(rules.endReason, contains('提前'));
    });

    test('清台后打进黑八但先碰错球判负', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [8]),
        onEight: true,
        calledPocket: 0,
      );
      expect(ruling.gameOver, isTrue);
      expect(ruling.winner, 1);
      expect(rules.endReason, contains('犯规'));
    });

    test('黑八与母球同时落袋判负', () {
      final rules = MatchRules()..isBreak = false;
      rules.groups[0] = PlayerGroup.solids;
      rules.groups[1] = PlayerGroup.stripes;
      rules.tableOpen = false;
      final ruling = rules.apply(
        outcome(pottedIds: [0, 8], firstContact: 8),
        onEight: true,
        calledPocket: 0,
      );
      expect(ruling.gameOver, isTrue);
      expect(ruling.winner, 1);
      expect(rules.endReason, contains('母球'));
    });
  });
}
