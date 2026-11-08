import '../core/match_controller.dart';
import '../core/table_geometry.dart';

/// 对局页底部/侧栏的提示文案，按练习、指袋与对局阶段分支。
String gameHint(MatchController controller) {
  if (controller.isPractice) {
    if (controller.isEditingBalls) return '摆球模式：拖动任意球调整位置';
    if (controller.phase == MatchPhase.shooting) return '球在运动中…';
    return '自由练习：拖动球台瞄准，可摆球或重打本杆';
  }
  if (controller.needsPocketCall) {
    final called = controller.calledPocket;
    return called == null
        ? '攻打黑八：先点击袋口指定目标袋'
        : '已指定 ${TableGeometry.pocketNames[called]} · 调整力度后击球';
  }
  return switch (controller.phase) {
    MatchPhase.gameOver => '${controller.matchTitle} · 对局结束',
    MatchPhase.shooting => '球在运动中…',
    MatchPhase.aiThinking => '电脑思考中…',
    MatchPhase.placingCue => '自由球：拖动母球到合法位置',
    MatchPhase.aiming => controller.isHumanTurn ? '拖动球台瞄准，调整力度后击球' : '电脑瞄准中…',
  };
}
