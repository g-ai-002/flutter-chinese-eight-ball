import 'package:flutter/material.dart';

import '../../core/match_record.dart';
import '../../core/replay_player.dart';
import '../../theme/app_theme.dart';

/// 逐杆列表：点击任意一杆跳到该杆开始前。
class ReplayShotList extends StatelessWidget {
  const ReplayShotList({
    super.key,
    required this.player,
    required this.record,
    this.horizontal = false,
  });

  final ReplayPlayer player;
  final MatchRecord record;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activeIndex = player.atEnd ? player.total - 1 : player.index;
    final list = ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: record.shots.length,
      separatorBuilder: (_, _) =>
          SizedBox(width: horizontal ? 8 : 0, height: horizontal ? 0 : 6),
      itemBuilder: (context, index) => _ShotTile(
        shot: record.shots[index],
        index: index,
        playerName: record.playerName(record.shots[index].player),
        active: index == activeIndex,
        width: horizontal ? 196 : null,
        onTap: () => player.seek(index),
      ),
    );

    if (horizontal) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Row(
            children: [
              Text(
                '逐杆记录',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${record.shotCount} 杆',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: list),
      ],
    );
  }
}

class _ShotTile extends StatelessWidget {
  const _ShotTile({
    required this.shot,
    required this.index,
    required this.playerName,
    required this.active,
    required this.onTap,
    this.width,
  });

  final ReplayShot shot;
  final int index;
  final String playerName;
  final bool active;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final potted = shot.potted.where((id) => id != 0).toList();
    return SizedBox(
      width: width,
      child: Material(
        color: active
            ? colors.primaryContainer.withValues(alpha: 0.6)
            : colors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? colors.primary.withValues(alpha: 0.55)
                    : colors.outline.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            playerName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (potted.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '打进 ${potted.map((id) => '#$id').join('、')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: appGold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shot.result,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
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
