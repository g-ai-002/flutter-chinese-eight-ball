import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 玩法规则：中式黑八规则要点与操作方式。
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('玩法规则')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              children: [
                const _Hero(),
                const SizedBox(height: 20),
                const _Section(
                  title: '目标',
                  body:
                      '使用母球击打目标球入袋。开球后首个合法落袋的球决定双方球组：'
                      '1-7 号为全色球，9-15 号为花色球。先清空本方 7 颗球，'
                      '再合法打进 8 号黑八者获胜。',
                ),
                const _Section(
                  title: '开球',
                  body:
                      '母球置于开球线后，向三角球堆方向击球。开球必须先碰到球堆，'
                      '碰撞后无球落袋也无球碰库视为犯规。开球时黑八落袋则重新摆球，'
                      '由同一方再次开球。',
                ),
                const _Section(
                  title: '球组归属',
                  body:
                      '开球后球台处于开放状态，双方可先击打任意非黑八球。'
                      '首次合法进球后，落袋球的花色归击球方，另一花色归对手；'
                      '此后必须先碰到本方球。',
                ),
                const _Section(
                  title: '犯规与自由球',
                  body:
                      '以下情况判犯规：母球落袋、空杆未碰到任何球、先碰到对方球或黑八、'
                      '碰撞后既无球落袋也无球碰库。犯规后交换球权，'
                      '对手获得自由球，可将母球摆放在台面任意合法位置。',
                ),
                const _Section(
                  title: '黑八胜负',
                  body:
                      '清空本方球组后，需要先点击袋口指定黑八目标袋，再把黑八打进该袋口才算获胜。'
                      '若在本方球未清空时黑八落袋、黑八落入非指定袋口，'
                      '或黑八与母球同时落袋，均判负。',
                ),
                const _Section(
                  title: '自由练习',
                  body:
                      '练习模式没有回合、犯规与胜负限制。点击球台上方的「摆球」后，'
                      '可拖动任意球调整位置；出杆后可点「重打」恢复上一杆的球局。'
                      '母球落袋会自动放回开球点，适合反复练习走位与薄球。',
                ),
                const _Section(
                  title: '对局回放',
                  body:
                      '每局人机或双人对战结束后会自动保存逐杆记录，最多保留最近 10 场。'
                      '在首页「最近对局」中可选择任意一场回放：播放、暂停、'
                      '拖动进度或点击单杆跳转，逐杆复盘走位与失误。记录只保存在本机。',
                ),
                const _Section(
                  title: '操作方式',
                  body:
                      '· 拖动球台：调整瞄准方向，点击球体可吸附到球心\n'
                      '· 力度滑杆：控制出杆力度，右侧按钮微调 0.3°\n'
                      '· 击球按钮：出杆，等待所有球停稳\n'
                      '· 指袋：攻打黑八时点击袋口标记选择目标袋\n'
                      '· 自由球：拖动母球到合法位置松手摆放',
                ),
                const _Section(
                  title: '小提示',
                  body:
                      '薄球与远台球对角度更敏感，可先点击目标球吸附球心，'
                      '再用微调按钮校准。开球力度建议 85% 以上，'
                      '中袋附近的球优先考虑低力度轻推。',
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '中式黑八 · 一杆定乾坤',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.7),
            colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF17181A),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F4E8),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '8',
                style: TextStyle(
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17181A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('中式黑八', style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '全色与花色各七颗，清台后攻打黑八',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.sports_bar_outlined, color: appGold, size: 26),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: colors.onSurface.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}
