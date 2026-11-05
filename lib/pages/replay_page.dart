import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/match_record.dart';
import '../core/replay_player.dart';
import '../flame/replay_game.dart';
import '../flame/table_layout.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 对局回放页：球台重演、逐杆跳转与杆次列表。
class ReplayPage extends StatefulWidget {
  const ReplayPage({super.key, required this.record});

  final MatchRecord record;

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  late final ReplayPlayer _player;
  ReplayGame? _game;

  @override
  void initState() {
    super.initState();
    _player = ReplayPlayer(widget.record);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    _game = ReplayGame(
      player: _player,
      settings: context.read<SettingsProvider>(),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) return const Scaffold(body: SizedBox.shrink());
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('对局回放'),
            Text(
              formatDateTime(widget.record.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _player,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 900 && constraints.maxHeight >= 520;
              return wide
                  ? _buildWide(game, constraints)
                  : _buildNarrow(game, constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWide(ReplayGame game, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                _SummaryBar(player: _player, record: widget.record),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: _buildTable(
                      game,
                      constraints.maxWidth - 360,
                      constraints.maxHeight - 150,
                    ),
                  ),
                ),
                _ReplayControls(player: _player),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: _ShotList(player: _player, record: widget.record),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow(ReplayGame game, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        children: [
          _SummaryBar(player: _player, record: widget.record, compact: true),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _buildTable(
                game,
                constraints.maxWidth,
                constraints.maxHeight - 268,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _ReplayControls(player: _player, compact: true),
          const SizedBox(height: 4),
          SizedBox(
            height: 118,
            child: _ShotList(player: _player, record: widget.record, horizontal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(ReplayGame game, double maxWidth, double maxHeight) {
    const aspect = TableLayout.aspectRatio;
    var width = math.min(maxWidth, maxHeight * aspect);
    if (width <= 0) width = math.min(maxWidth, 320);
    final height = width / aspect;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          Positioned(
            left: 8,
            top: 8,
            right: 8,
            child: Align(
              alignment: Alignment.topLeft,
              child: _ShotOverlay(player: _player),
            ),
          ),
        ],
      ),
    );
  }
}

/// 对局结果与来源信息。
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.player,
    required this.record,
    this.compact = false,
  });

  final ReplayPlayer player;
  final MatchRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 8 : 10, 14, compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(
            record.playerWin
                ? Icons.emoji_events_outlined
                : Icons.sports_bar_outlined,
            size: 22,
            color: record.playerWin ? appGold : colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${record.subtitle}${compact ? '' : ' · ${record.endReason}'}',
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${player.displayIndex} / ${record.shotCount} 杆',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 当前杆的球手与裁定结果。
class _ShotOverlay extends StatelessWidget {
  const _ShotOverlay({required this.player});

  final ReplayPlayer player;

  @override
  Widget build(BuildContext context) {
    final shot = player.activeShot;
    if (shot == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final heading = player.atEnd
        ? '终局 · ${player.record.playerName(shot.player)}'
        : '第 ${player.displayIndex} 杆 · ${player.record.playerName(shot.player)}';
    final result = player.atEnd ? player.record.endReason : shot.result;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            result,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 播放 / 暂停、上一杆 / 下一杆与进度滑杆。
class _ReplayControls extends StatelessWidget {
  const _ReplayControls({required this.player, this.compact = false});

  final ReplayPlayer player;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '上一杆',
              onPressed: player.index <= 0 ? null : player.previous,
              icon: const Icon(Icons.skip_previous, size: 22),
            ),
            Expanded(
              child: Slider(
                value: player.progress.clamp(0.0, 1.0),
                onChanged: player.canPlay
                    ? (value) => player.seek((value * player.total).round())
                    : null,
              ),
            ),
            IconButton(
              tooltip: '下一杆',
              onPressed: player.atEnd ? null : player.next,
              icon: const Icon(Icons.skip_next, size: 22),
            ),
            IconButton.filled(
              tooltip: player.isPlaying
                  ? '暂停'
                  : (player.atEnd ? '重新播放' : '播放'),
              onPressed: player.canPlay ? player.togglePlay : null,
              icon: Icon(
                player.isPlaying
                    ? Icons.pause
                    : (player.atEnd ? Icons.replay : Icons.play_arrow),
                size: 22,
              ),
            ),
          ],
        ),
        if (!compact)
          Text(
            '第 ${player.displayIndex} / ${player.total} 杆 · '
            '${player.isPlaying ? '播放中' : (player.atEnd ? '已结束' : '已暂停')}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// 逐杆列表：点击任意一杆跳到该杆开始前。
class _ShotList extends StatelessWidget {
  const _ShotList({
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
      separatorBuilder: (_, _) => SizedBox(
        width: horizontal ? 8 : 0,
        height: horizontal ? 0 : 6,
      ),
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
        color: active ? colors.primaryContainer.withValues(alpha: 0.6) : colors.surface,
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
                    color: active ? colors.primary : colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? colors.onPrimary : colors.onSurfaceVariant,
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
