import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../services/log_service.dart';
import 'ai.dart';
import 'ball.dart';
import 'match_record.dart';
import 'match_recorder.dart';
import 'physics.dart';
import 'practice_preset.dart';
import 'practice_session.dart';
import 'rules.dart';
import 'table_geometry.dart';
import 'vec.dart';

enum GameMode {
  vsAi('人机对战'),
  twoPlayers('双人对战'),
  practice('自由练习');

  const GameMode(this.label);

  final String label;
}

enum MatchPhase { aiming, shooting, aiThinking, placingCue, gameOver }

/// 对局控制器：负责摆球、出杆、物理推进、回合裁定与 AI 行动。
///
/// 界面的动画帧由 Flame 的 update 调用 [tick] 驱动，击球过程中的音效与
/// 落袋动画从 [pendingEffects] 取用。
class MatchController extends ChangeNotifier {
  MatchController({
    required this.mode,
    this.difficulty = AiDifficulty.normal,
    this.aiStrength = 0.5,
    this.humanSide = 0,
    this.aiThinkDelay = const Duration(milliseconds: 520),
    this.autoPlayAi = true,
    math.Random? random,
  }) : _ai = EightBallAi(random: random),
       _rules = MatchRules(),
       _practice = PracticeSession(),
       _recorder = MatchRecorder(
         mode: mode.name,
         modeLabel: mode.label,
         difficultyLabel: AiTuning.of(difficulty, aiStrength).label,
         humanSide: humanSide,
       ),
       _simulation = ShotSimulation(balls: TableGeometry.rackBalls()) {
    if (isPractice) _practice.reset(preset: PracticePreset.rack);
    aimAngle = angleOf(cuePosition, TableGeometry.footSpot);
    _pushLog(isPractice ? '自由练习：拖动球台瞄准，可随时摆球或重打本杆' : '开球：${playerName(0)}先手');
    if (autoPlayAi && _isAiTurn) {
      _scheduleAiTurn();
    }
  }

  static const double defaultPower = 0.72;

  final GameMode mode;
  final int humanSide;
  final AiDifficulty difficulty;

  /// 自定义 AI 强度（0~1），仅在难度为自定义时生效。
  final double aiStrength;
  final Duration aiThinkDelay;

  /// 测试时置为 false，避免异步 AI 影响断言。
  final bool autoPlayAi;

  final EightBallAi _ai;
  final PracticeSession _practice;
  final MatchRecorder _recorder;
  final List<String> _history = [];
  final List<ShotEvent> pendingEffects = [];

  MatchRules _rules;
  ShotSimulation _simulation;
  MatchPhase _phase = MatchPhase.aiming;
  double aimAngle = 0;
  double power = defaultPower;
  int? _onEightBefore;
  int _effectCursor = 0;
  bool _disposed = false;
  bool _aiRunning = false;
  int _generation = 0;
  int? _calledPocket;
  MatchRecord? _finishedRecord;

  MatchRules get rules => _rules;
  ShotSimulation get simulation => _simulation;
  List<BallState> get balls => _simulation.balls;
  MatchPhase get phase => _phase;
  List<String> get log => List.unmodifiable(_history);
  BallState get cueBall => _simulation.cueBall;
  Vec2 get cuePosition => cueBall.position;
  int get currentPlayer => _rules.current;
  bool get isBreak => _rules.isBreak;
  bool get ballInHand => _rules.ballInHand;
  bool get isAiTurn => _isAiTurn;
  bool get isHumanTurn => !_isAiTurn;
  bool get isPractice => mode == GameMode.practice;
  bool get isEditingBalls => _practice.editing;
  PracticePreset? get practicePreset => _practice.preset;
  int get shotCount => isPractice ? _practice.shots : _rules.shotNumber;
  bool get canUndoPracticeShot =>
      isPractice && _practice.canUndo && _phase == MatchPhase.aiming;

  /// 当前玩家能否瞄准：AI 回合、球运动中与练习摆球时不可操作。
  bool get canAim =>
      _phase == MatchPhase.aiming && isHumanTurn && !isEditingBalls;

  /// 当前玩家能否出杆：攻打黑八时还必须先指定袋口。
  bool get canShoot => canAim && (!needsPocketCall || _calledPocket != null);

  /// 攻打黑八时已指定的袋口；未指定为 null。
  int? get calledPocket => _calledPocket;

  /// 对局结束时生成的逐杆记录，供保存与回放；练习模式与对局中为 null。
  MatchRecord? get finishedRecord => _finishedRecord;

  /// 终局标题：双人显示获胜方，人机站在玩家视角。
  String get matchTitle {
    final result = _rules.winner ?? 0;
    if (mode == GameMode.twoPlayers) return '${playerName(result)}获胜';
    return result == humanSide ? '你赢了' : '电脑获胜';
  }

  /// 当前是否需要先指袋才能出杆（练习模式不受此限制）。
  bool get needsPocketCall =>
      !isPractice && _phase == MatchPhase.aiming && onEightFor(currentPlayer);

  bool get _isAiTurn => mode == GameMode.vsAi && _rules.current != humanSide;

  /// AI 只允许在瞄准或摆球阶段行动，避免在球运动时被旧定时器打断。
  bool get _canAiAct =>
      _phase == MatchPhase.aiming || _phase == MatchPhase.placingCue;

  String playerName(int player) {
    if (isPractice) return '练习';
    if (mode == GameMode.twoPlayers) return '玩家${player == 0 ? '一' : '二'}';
    return player == humanSide ? '玩家' : '电脑';
  }

  /// 指定黑八目标袋口，仅在需要指袋时生效。
  void setCalledPocket(int index) {
    if (!needsPocketCall) return;
    if (index < 0 || index >= TableGeometry.pockets.length) return;
    if (_calledPocket == index) return;
    _calledPocket = index;
    _pushLog('指定黑八袋口：${TableGeometry.pocketNames[index]}');
    notifyListeners();
  }

  /// 当前轮次是否应攻打黑八（本方花色已清空）。
  bool onEightFor(int player) {
    final group = _rules.groupOf(player);
    if (group == null) return false;
    return !balls.any((ball) => ball.active && ball.kind == group.kind);
  }

  int remainingCount(PlayerGroup group) =>
      balls.where((ball) => ball.active && ball.kind == group.kind).length;

  int get remainingEight =>
      balls.where((ball) => ball.active && ball.isEight).length;

  /// 本方还需打进的球数（清台后显示黑八 1 颗）。
  int remainingFor(int player) {
    final group = _rules.groupOf(player);
    if (group == null) return 7;
    final count = remainingCount(group);
    return count == 0 ? remainingEight : count;
  }

  // 瞄准只影响 Flame 的下一帧绘制，不触发界面 rebuild，避免拖动时整页重建。
  void setAimAngle(double angle) => aimAngle = angle;

  void adjustAim(double delta) => aimAngle += delta;

  void setPower(double value) {
    power = value.clamp(0.05, 1.0);
    notifyListeners();
  }

  /// 指向台面上的某个坐标，用于拖动瞄准与点击球体吸附。
  void aimAt(Vec2 point) {
    if ((point - cuePosition).lengthSquared < 0.0004) return;
    aimAngle = angleOf(cuePosition, point);
  }

  /// 自由球摆放：位置合法才落地，成功返回 true。
  bool placeCue(Vec2 position) {
    if (_phase != MatchPhase.placingCue) return false;
    if (!TableGeometry.isValidCuePlacement(
      position,
      obstacles: balls.where((ball) => ball.isCue == false),
    )) {
      return false;
    }
    _simulation.placeCue(position);
    _rules.ballInHand = false;
    _phase = MatchPhase.aiming;
    aimAngle = angleOf(position, TableGeometry.footSpot);
    _pushLog('${playerName(currentPlayer)}摆放母球');
    notifyListeners();
    if (_isAiTurn) _scheduleAiTurn();
    return true;
  }

  void shoot() {
    if (!canShoot) return;
    _fire();
  }

  /// 进入练习摆球：可拖动任意球调整位置。
  void beginBallEdit() {
    if (!isPractice || _phase != MatchPhase.aiming) return;
    _practice.beginEdit();
    _pushLog('摆球模式：拖动任意球调整位置');
    notifyListeners();
  }

  void endBallEdit() {
    if (!_practice.editing) return;
    _practice.endEdit();
    aimAngle = angleOf(cuePosition, TableGeometry.footSpot);
    notifyListeners();
  }

  /// 练习模式移动一颗球，位置合法才生效。
  bool moveBall(int id, Vec2 position) {
    if (!isPractice || !_practice.editing) return false;
    if (!TableGeometry.isValidBallPlacement(
      position,
      obstacles: balls,
      ignoreId: id,
    )) {
      return false;
    }
    for (final ball in balls) {
      if (ball.id != id) continue;
      ball.position = position;
      ball.velocity = Vec2.zero;
      if (ball.isCue) aimAngle = angleOf(position, TableGeometry.footSpot);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 练习模式：切换球型模板，清空杆数与上一杆快照。
  void applyPracticePreset(PracticePreset preset) {
    if (!isPractice || _phase != MatchPhase.aiming) return;
    _loadBalls(preset.layout());
    _practice.reset(preset: preset);
    _pushLog('练习球型：${preset.label}');
    notifyListeners();
  }

  /// 练习模式：把球局恢复到上一杆出杆前，便于重复练习同一杆。
  void undoPracticeShot() {
    if (!canUndoPracticeShot) return;
    final restore = _practice.restoreShot();
    if (restore == null) return;
    _loadBalls(restore);
    _phase = MatchPhase.aiming;
    _pushLog('已恢复上一杆的球局');
    notifyListeners();
  }

  void _fire() {
    _onEightBefore = onEightFor(currentPlayer) ? 1 : 0;
    if (isPractice) {
      _practice.capture(_simulation.balls);
    } else {
      _recorder.beginShot(
        player: currentPlayer,
        balls: balls,
        angle: aimAngle,
        power: power,
        calledPocket: _calledPocket,
      );
    }
    _simulation = ShotSimulation(balls: _simulation.balls);
    pendingEffects.clear();
    _effectCursor = 0;
    _simulation.strike(aimAngle, power);
    _phase = MatchPhase.shooting;
    _pushLog('${playerName(currentPlayer)}出杆');
    LogService.info(
      '出杆: 玩家=${playerName(currentPlayer)} 角度=${aimAngle.toStringAsFixed(3)} '
      '力度=${(power * 100).round()}%',
    );
    notifyListeners();
  }

  /// Flame 每帧调用：推进物理、收集特效、落定后裁定。
  void tick(double dt) {
    if (_phase != MatchPhase.shooting) return;
    _simulation.step(dt);
    _collectEffects();
    if (_simulation.settled) {
      _finishShot();
    }
  }

  void _collectEffects() {
    while (_effectCursor < _simulation.events.length) {
      pendingEffects.add(_simulation.events[_effectCursor]);
      _effectCursor++;
    }
    if (pendingEffects.length > 64) {
      pendingEffects.removeRange(0, pendingEffects.length - 64);
    }
  }

  void _finishShot() {
    final outcome = _simulation.outcome();
    if (isPractice) {
      _finishPracticeShot(outcome);
      return;
    }

    final ruling = _rules.apply(
      outcome,
      onEight: _onEightBefore == 1,
      calledPocket: _calledPocket,
    );
    _calledPocket = null;
    _recorder.endShot(result: ruling.message, potted: outcome.pottedIds);
    _pushLog(ruling.message);
    LogService.info(
      '裁定: 落袋=${outcome.pottedIds} 首碰=${outcome.firstContact} '
      '母球落袋=${outcome.cuePotted} 犯规=${ruling.foul} '
      '轮到=${playerName(_rules.current)}',
    );

    if (ruling.gameOver) {
      _phase = MatchPhase.gameOver;
      _finishedRecord = _recorder.finish(
        winner: ruling.winner ?? 0,
        winnerName: playerName(ruling.winner ?? 0),
        title: matchTitle,
        playerWin: mode == GameMode.twoPlayers || ruling.winner == humanSide,
        reason: ruling.endReason ?? ruling.message,
      );
      LogService.info(
        '对局结束: $matchTitle · ${ruling.endReason} · 共 ${_recorder.shotCount} 杆',
      );
      notifyListeners();
      return;
    }

    if (ruling.rerack) {
      _startRack();
      notifyListeners();
      if (_isAiTurn) _scheduleAiTurn();
      return;
    }

    if (_rules.ballInHand) {
      // 自由球期间把母球从台面移走，只保留待摆放的半透明预览。
      cueBall.active = false;
      _phase = MatchPhase.placingCue;
      if (_isAiTurn) {
        _autoPlaceCueForAi();
      }
      notifyListeners();
      if (_isAiTurn) _scheduleAiTurn();
      return;
    }

    _phase = MatchPhase.aiming;
    _restoreCueBall();
    aimAngle = angleOf(cueBall.position, TableGeometry.footSpot);
    notifyListeners();
    if (_isAiTurn) _scheduleAiTurn();
  }

  /// 练习模式没有回合与犯规：停稳后直接恢复瞄准，母球落袋则放回开球点。
  void _finishPracticeShot(ShotOutcome outcome) {
    _practice.recordShot();
    _restoreCueBall();
    _phase = MatchPhase.aiming;
    aimAngle = angleOf(cueBall.position, TableGeometry.footSpot);
    final potted = outcome.pottedIds.where((id) => id != 0).toList();
    final target = potted.isEmpty
        ? '本杆未进球'
        : '打进 ${potted.map((id) => '#$id').join('、')}';
    _pushLog(outcome.cuePotted ? '$target · 母球落袋，已放回开球点' : target);
    LogService.info(
      '练习: 落袋=${outcome.pottedIds} 首碰=${outcome.firstContact} '
      '杆数=${_practice.shots}',
    );
    notifyListeners();
  }

  /// 用给定球局替换台面，并同步清空特效、指袋与瞄准角。
  void _loadBalls(Iterable<BallState> balls, {bool placeCueAtHead = false}) {
    _simulation = ShotSimulation(balls: balls);
    if (placeCueAtHead) _simulation.placeCue(TableGeometry.headSpot);
    pendingEffects.clear();
    _effectCursor = 0;
    _calledPocket = null;
    aimAngle = angleOf(cuePosition, TableGeometry.footSpot);
  }

  void _startRack() {
    _loadBalls(TableGeometry.rackBalls(), placeCueAtHead: true);
    _rules.isBreak = true;
    _rules.ballInHand = false;
    _practice.reset(preset: isPractice ? PracticePreset.rack : null);
    _phase = MatchPhase.aiming;
    _pushLog('重新摆球');
  }

  void _autoPlaceCueForAi() {
    final spot = TableGeometry.nearestValidCueSpot(
      TableGeometry.headSpot,
      obstacles: balls,
    );
    if (spot == null) return;
    _simulation.placeCue(spot);
    _rules.ballInHand = false;
    _phase = MatchPhase.aiming;
  }

  void _restoreCueBall() {
    if (cueBall.active) return;
    _simulation.placeCue(_defaultCueSpot());
  }

  /// AI 没有明确线路时，退化为离黑八最近的袋口。
  int _nearestPocketToEight() {
    for (final ball in balls) {
      if (ball.active && ball.isEight) {
        return TableGeometry.nearestPocket(ball.position);
      }
    }
    return 0;
  }

  Vec2 _defaultCueSpot() {
    return TableGeometry.nearestValidCueSpot(
          TableGeometry.headSpot,
          obstacles: balls,
        ) ??
        TableGeometry.center;
  }

  void _scheduleAiTurn() {
    if (!autoPlayAi) return;
    final generation = _generation;
    Future<void>.delayed(aiThinkDelay, () {
      if (_disposed || generation != _generation) return;
      unawaited(playAiTurn());
    });
  }

  /// 让 AI 完成一次行动；测试可直接 await 此方法。
  Future<void> playAiTurn() async {
    if (_disposed || _aiRunning) return;
    if (!_isAiTurn || !_canAiAct) return;
    final generation = _generation;
    _aiRunning = true;
    _phase = MatchPhase.aiThinking;
    notifyListeners();

    if (!cueBall.active) {
      _autoPlaceCueForAi();
      if (!cueBall.active) {
        _aiRunning = false;
        _phase = MatchPhase.placingCue;
        notifyListeners();
        return;
      }
      notifyListeners();
    }

    if (aiThinkDelay > Duration.zero && autoPlayAi) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (_disposed || generation != _generation) {
        _aiRunning = false;
        return;
      }
    }

    final AiShot shot;
    if (_rules.isBreak) {
      shot = AiShot(
        angle: angleOf(cueBall.position, TableGeometry.footSpot) + 0.01,
        power: 0.95,
        score: 0,
      );
    } else {
      shot = _ai.decide(
        balls: balls,
        group: _rules.currentGroup,
        onEight: onEightFor(currentPlayer),
        tuning: AiTuning.of(difficulty, aiStrength),
      );
      if (shot.isSafety) {
        _pushLog('${playerName(currentPlayer)}选择防守');
        LogService.info(
          'AI 防守: 目标球=${shot.targetBallId} '
          '力度=${(shot.power * 100).round()}% 评分=${shot.score.toStringAsFixed(1)}',
        );
      }
    }

    // 攻打黑八时 AI 自动指定候选线路的袋口，避免因未指袋而无法出杆。
    if (onEightFor(currentPlayer)) {
      final pocket = shot.pocketIndex ?? _nearestPocketToEight();
      _calledPocket = pocket;
    }

    aimAngle = shot.angle;
    power = shot.power;
    _phase = MatchPhase.aiming;
    notifyListeners();

    if (aiThinkDelay > Duration.zero && autoPlayAi) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (_disposed || generation != _generation) {
        _aiRunning = false;
        return;
      }
    }

    _aiRunning = false;
    if (_disposed ||
        generation != _generation ||
        _phase != MatchPhase.aiming ||
        !_isAiTurn) {
      return;
    }
    _fire();
  }

  void restart() {
    _generation++;
    _rules = MatchRules();
    _calledPocket = null;
    _recorder.clear();
    _finishedRecord = null;
    _startRack();
    _history.clear();
    _pushLog(isPractice ? '自由练习：拖动球台瞄准，可随时摆球或重打本杆' : '开球：${playerName(0)}先手');
    power = defaultPower;
    notifyListeners();
    if (_isAiTurn) _scheduleAiTurn();
  }

  void _pushLog(String message) {
    _history.add(message);
    if (_history.length > 8) _history.removeAt(0);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
