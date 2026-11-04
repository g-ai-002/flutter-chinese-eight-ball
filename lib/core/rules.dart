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

  /// 判定一杆的结果。[onEight] 表示击球前是否已经清完本方花色。
  ShotRuling apply(ShotOutcome outcome, {required bool onEight}) {
    shotNumber++;
    final shootingPlayer = current;
    final wasBreak = isBreak;
    final opponent = opponentOf(shootingPlayer);

    if (wasBreak && outcome.eightPotted) {
      isBreak = false;
      ballInHand = false;
      return const ShotRuling(
        foul: false,
        keepTurn: true,
        message: '开球黑八落袋，重新摆球开球',
        rerack: true,
      );
    }
    isBreak = false;

    String? foulReason;
    if (outcome.cuePotted) {
      foulReason = '母球落袋';
    } else if (outcome.firstContact == null) {
      foulReason = '空杆，未碰到任何球';
    } else {
      final firstKind = kindOfBall(outcome.firstContact!);
      final group = groups[shootingPlayer];
      if (tableOpen) {
        if (firstKind == BallKind.eight) {
          foulReason = '开放球台不能先碰黑八';
        }
      } else if (group != null && !onEight) {
        if (firstKind != group.kind) {
          foulReason = firstKind == BallKind.eight ? '先碰到黑八' : '先碰到对方的球';
        }
      } else if (group != null && onEight) {
        if (firstKind != BallKind.eight) {
          foulReason = '未先碰黑八';
        }
      }
    }

    if (foulReason == null &&
        outcome.anyPotted == false &&
        outcome.firstContact != null &&
        !outcome.cushionAfterContact) {
      foulReason = '碰撞后无球碰库';
    }

    final foul = foulReason != null;

    // 黑八落袋的胜负先于普通犯规处理：清台后合法打进黑八即胜，
    // 提前落袋、母球同时落袋或开球外的犯规都判负。
    if (outcome.eightPotted) {
      over = true;
      if (onEight && !outcome.cuePotted) {
        winner = shootingPlayer;
        endReason = '清台后打进黑八';
      } else {
        winner = opponent;
        endReason = outcome.cuePotted
            ? '黑八与母球同时落袋'
            : (onEight ? '打进黑八时母球落袋' : '黑八提前落袋');
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

    if (foul) {
      current = opponent;
      ballInHand = true;
      return ShotRuling(
        foul: true,
        keepTurn: false,
        message: '犯规：$foulReason · 对手自由球',
        foulReason: foulReason,
      );
    }

    var assigned = false;
    if (tableOpen) {
      final firstObject = outcome.firstPottedObject;
      if (firstObject != null && firstObject != 8) {
        final group = PlayerGroup.ofBall(kindOfBall(firstObject));
        groups[shootingPlayer] = group;
        groups[opponent] = group == PlayerGroup.solids
            ? PlayerGroup.stripes
            : PlayerGroup.solids;
        tableOpen = false;
        assigned = true;
      }
    }

    final ownGroup = groups[shootingPlayer];
    final pottedOwn = outcome.pottedIds.any((id) {
      if (id == 0 || id == 8) return false;
      if (ownGroup == null) return true;
      return kindOfBall(id) == ownGroup.kind;
    });

    if (pottedOwn) {
      final groupText = assigned ? ' · 本局目标：${ownGroup!.label}' : '';
      return ShotRuling(
        foul: false,
        keepTurn: true,
        message: '进球，继续击球$groupText',
      );
    }

    current = opponent;
    ballInHand = false;
    return const ShotRuling(foul: false, keepTurn: false, message: '未进球，交换球权');
  }

  /// 依据球号推断花色，无需依赖台面状态。
  static BallKind kindOfBall(int id) {
    if (id == 0) return BallKind.cue;
    if (id == 8) return BallKind.eight;
    return id < 8 ? BallKind.solid : BallKind.stripe;
  }
}
