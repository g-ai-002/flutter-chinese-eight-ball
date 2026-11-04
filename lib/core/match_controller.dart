import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../services/log_service.dart';
import 'ai.dart';
import 'ball.dart';
import 'physics.dart';
import 'rules.dart';
import 'table_geometry.dart';
import 'vec.dart';

enum GameMode {
  vsAi('人机对战'),
  twoPlayers('双人对战');

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
    this.humanSide = 0,
    this.aiThinkDelay = const Duration(milliseconds: 520),
    this.autoPlayAi = true,
    math.Random? random,
  }) : _ai = EightBallAi(random: random),
       _rules = MatchRules(),
       _simulation = ShotSimulation(balls: TableGeometry.rackBalls()) {
    aimAngle = angleOf(cuePosition, TableGeometry.footSpot);
    _pushLog('开球：${playerName(0)}先手');
    if (autoPlayAi && _isAiTurn) {
      _scheduleAiTurn();
    }
  }

  static const double defaultPower = 0.72;

  final GameMode mode;
  final int humanSide;
  final AiDifficulty difficulty;
  final Duration aiThinkDelay;

  /// 测试时置为 false，避免异步 AI 影响断言。
  final bool autoPlayAi;

  final EightBallAi _ai;
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
  bool get isPlacing => _phase == MatchPhase.placingCue;

  bool get _isAiTurn => mode == GameMode.vsAi && _rules.current != humanSide;

  String playerName(int player) {
    if (mode == GameMode.twoPlayers) return '玩家${player == 0 ? '一' : '二'}';
    return player == humanSide ? '玩家' : '电脑';
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
    if (_phase != MatchPhase.aiming || _isAiTurn) return;
    _fire();
  }

  void _fire() {
    _onEightBefore = onEightFor(currentPlayer) ? 1 : 0;
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
    final ruling = _rules.apply(outcome, onEight: _onEightBefore == 1);
    _pushLog(ruling.message);
    LogService.info(
      '裁定: 落袋=${outcome.pottedIds} 首碰=${outcome.firstContact} '
      '母球落袋=${outcome.cuePotted} 犯规=${ruling.foul} '
      '轮到=${playerName(_rules.current)}',
    );

    if (ruling.gameOver) {
      _phase = MatchPhase.gameOver;
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
    if (!cueBall.active) {
      _simulation.placeCue(_defaultCueSpot());
    }
    aimAngle = angleOf(cueBall.position, TableGeometry.footSpot);
    notifyListeners();
    if (_isAiTurn) _scheduleAiTurn();
  }

  void _startRack() {
    _simulation = ShotSimulation(balls: TableGeometry.rackBalls())
      ..placeCue(TableGeometry.headSpot);
    _effectCursor = 0;
    _rules.isBreak = true;
    _rules.ballInHand = false;
    _phase = MatchPhase.aiming;
    aimAngle = angleOf(cueBall.position, TableGeometry.footSpot);
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

  Vec2 _defaultCueSpot() {
    return TableGeometry.nearestValidCueSpot(
          TableGeometry.headSpot,
          obstacles: balls,
        ) ??
        TableGeometry.center;
  }

  void _scheduleAiTurn() {
    if (!autoPlayAi) return;
    Future<void>.delayed(aiThinkDelay, () {
      if (_disposed) return;
      unawaited(playAiTurn());
    });
  }

  /// 让 AI 完成一次行动；测试可直接 await 此方法。
  Future<void> playAiTurn() async {
    if (_disposed || _aiRunning) return;
    if (!_isAiTurn || _phase == MatchPhase.gameOver) return;
    final generation = _generation;
    _aiRunning = true;
    _phase = MatchPhase.aiThinking;
    notifyListeners();

    if (!cueBall.active) {
      _autoPlaceCueForAi();
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
        difficulty: difficulty,
      );
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
    _startRack();
    _history.clear();
    _pushLog('开球：${playerName(0)}先手');
    pendingEffects.clear();
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
