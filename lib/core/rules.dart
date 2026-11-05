import 'ball.dart';
import 'physics.dart';

/// 一杆的裁定结果，供控制器更新界面与回合。
class ShotRuling {
  const ShotRuling({
    required this.foul,
    required this.keepTurn,
    required this.message,
    this.foulReason,
    this.gameOver = false,
    this.winner,
    this.endReason,
    this.rerack = false,
  });

  final bool foul;
  final bool keepTurn;
  final String message;
  final String? foulReason;
  final bool gameOver;
  final int? winner;
  final String? endReason;

  /// 开球时黑八落袋，需要重新摆球。
  final bool rerack;
}

/// 中式黑八规则：开放球台、花色归属、犯规判罚、黑八胜负裁定。
///
/// 规则只依据物理模拟给出的事实判定，不直接修改球的位置；母球落袋后的
/// 自由球摆放由控制器处理。
class MatchRules {
  MatchRules();

  int current = 0;
  final List<PlayerGroup?> groups = [null, null];
  bool tableOpen = true;
  bool isBreak = true;
  bool over = false;
  int? winner;
  String? endReason;
  bool ballInHand = false;
  int shotNumber = 0;

  PlayerGroup? get currentGroup => groups[current];
  PlayerGroup? groupOf(int player) => groups[player];

  int opponentOf(int player) => 1 - player;

  /// 判定一杆的结果。[onEight] 表示击球前是否已经清完本方花色，
  /// [calledPocket] 是攻打黑八时指定的袋口编号（0-5）。
  ShotRuling apply(
    ShotOutcome outcome, {
    required bool onEight,
    int? calledPocket,
  }) {
    shotNumber++;
    final shooter = current;
    final wasBreak = isBreak;
    isBreak = false;

    // 开球时黑八落袋不计胜负，重新摆球后由同一球手再次开球。
    if (wasBreak && outcome.eightPotted) {
      ballInHand = false;
      return const ShotRuling(
        foul: false,
        keepTurn: true,
        message: '开球黑八落袋，重新摆球开球',
        rerack: true,
      );
    }

    final foulReason = _foulReason(outcome, shooter, onEight);
    if (outcome.eightPotted) {
      return _settleEightBall(
        outcome,
        shooter,
        onEight: onEight,
        foulReason: foulReason,
        calledPocket: calledPocket,
      );
    }
    if (foulReason != null) return _settleFoul(foulReason);
    return _settleLegalShot(outcome, shooter);
  }

  /// 黑八落袋即终局：清台后打进指定袋口获胜，其余情况判负。
  ShotRuling _settleEightBall(
    ShotOutcome outcome,
    int shooter, {
    required bool onEight,
    required String? foulReason,
    required int? calledPocket,
  }) {
    final foul = foulReason != null;
    final eightPocket = outcome.potted
        .firstWhere((event) => event.ballId == 8)
        .pocketIndex;
    final pocketMatched = calledPocket != null && calledPocket == eightPocket;
    over = true;
    if (onEight && !foul && !outcome.cuePotted && pocketMatched) {
      winner = shooter;
      endReason = '清台后打进黑八';
    } else {
      winner = opponentOf(shooter);
      if (outcome.cuePotted) {
        endReason = '黑八与母球同时落袋';
      } else if (!onEight) {
        endReason = '黑八提前落袋';
      } else if (foulReason != null) {
        endReason = '打进黑八时犯规：$foulReason';
      } else if (calledPocket == null) {
        endReason = '未指定袋口，黑八落袋判负';
      } else {
        endReason = '黑八落入非指定袋口';
      }
    }
    ballInHand = false;
    return ShotRuling(
      foul: foul,
      keepTurn: false,
      message: endReason!,
      foulReason: foulReason,
      gameOver: true,
      winner: winner,
      endReason: endReason,
    );
  }

  ShotRuling _settleFoul(String reason) {
    current = opponentOf(current);
    ballInHand = true;
    return ShotRuling(
      foul: true,
      keepTurn: false,
      message: '犯规：$reason · 对手自由球',
      foulReason: reason,
    );
  }

  ShotRuling _settleLegalShot(ShotOutcome outcome, int shooter) {
    final assigned = _assignGroups(shooter, outcome);
    final ownGroup = groups[shooter];

    if (_pottedOwnBall(outcome, ownGroup)) {
      final groupText = assigned ? ' · 本局目标：${ownGroup!.label}' : '';
      return ShotRuling(
        foul: false,
        keepTurn: true,
        message: '进球，继续击球$groupText',
      );
    }

    current = opponentOf(shooter);
    ballInHand = false;
    return const ShotRuling(foul: false, keepTurn: false, message: '未进球，交换球权');
  }

  /// 开放球台首颗合法落袋的目标球决定球组，返回是否完成定组。
  bool _assignGroups(int shooter, ShotOutcome outcome) {
    if (!tableOpen) return false;
    final firstObject = outcome.firstPottedObject;
    if (firstObject == null || firstObject == 8) return false;

    final group = PlayerGroup.ofBall(kindOfBall(firstObject));
    groups[shooter] = group;
    groups[opponentOf(shooter)] = group == PlayerGroup.solids
        ? PlayerGroup.stripes
        : PlayerGroup.solids;
    tableOpen = false;
    return true;
  }

  bool _pottedOwnBall(ShotOutcome outcome, PlayerGroup? group) {
    return outcome.pottedIds.any((id) {
      if (id == 0 || id == 8) return false;
      if (group == null) return true;
      return kindOfBall(id) == group.kind;
    });
  }

  /// 按优先级归并犯规：母球落袋 > 空杆 > 先碰错球 > 碰撞后无球碰库。
  String? _foulReason(ShotOutcome outcome, int shooter, bool onEight) {
    final contactReason = _contactFoulReason(outcome, shooter, onEight);
    if (contactReason != null) return contactReason;
    if (!outcome.anyPotted &&
        outcome.firstContact != null &&
        !outcome.cushionAfterContact) {
      return '碰撞后无球碰库';
    }
    return null;
  }

  String? _contactFoulReason(ShotOutcome outcome, int shooter, bool onEight) {
    if (outcome.cuePotted) return '母球落袋';

    final firstContact = outcome.firstContact;
    if (firstContact == null) return '空杆，未碰到任何球';

    final firstKind = kindOfBall(firstContact);
    if (tableOpen) {
      return firstKind == BallKind.eight ? '开放球台不能先碰黑八' : null;
    }

    final group = groups[shooter];
    if (group == null) return null;
    if (onEight) {
      return firstKind == BallKind.eight ? null : '未先碰黑八';
    }
    if (firstKind == group.kind) return null;
    return firstKind == BallKind.eight ? '先碰到黑八' : '先碰到对方的球';
  }

  /// 依据球号推断花色，无需依赖台面状态。
  static BallKind kindOfBall(int id) {
    if (id == 0) return BallKind.cue;
    if (id == 8) return BallKind.eight;
    return id < 8 ? BallKind.solid : BallKind.stripe;
  }
}
