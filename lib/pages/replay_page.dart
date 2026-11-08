import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/match_record.dart';
import '../core/replay_player.dart';
import '../flame/replay_game.dart';
import '../flame/table_layout.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import 'table_orientation.dart';
import 'widgets/replay_controls.dart';
import 'widgets/replay_shot_list.dart';
import 'widgets/replay_shot_overlay.dart';
import 'widgets/replay_summary_bar.dart';

/// 对局回放页：球台重演、逐杆跳转与杆次列表。
///
/// 球台只吃摘要、控制条与逐杆条之外的空间并等比缩放，不再按固定像素扣减，
/// 因此横屏手机与矮窗口也能得到尽可能大的球台。
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
    TableOrientation.attach();
    _player = ReplayPlayer(widget.record);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    _game = ReplayGame(player: _player, settings: context.read<SettingsProvider>());
  }

  @override
  void dispose() {
    _game?.pauseEngine();
    _game = null;
    TableOrientation.detach();
    _player.dispose();
    super.dispose();
  }

  /// 矮屏隐藏逐杆条后用抽屉查看，保证球台优先。
  Future<void> _showShotList() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: math.min(420, MediaQuery.sizeOf(sheetContext).height * 0.6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ReplayShotList(player: _player, record: widget.record),
          ),
        ),
      ),
    );
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
        actions: [
          IconButton(
            tooltip: '逐杆记录',
            onPressed: _showShotList,
            icon: const Icon(Icons.list_alt, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _player,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              TableOrientation.sync(constraints.biggest);
              final wide = constraints.maxWidth >= 900 && constraints.maxHeight >= 520;
              return wide ? _buildWide(game, constraints) : _buildNarrow(game, constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWide(ReplayGame game, BoxConstraints constraints) {
    final panelWidth = math.min(320.0, constraints.maxWidth * 0.32);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                ReplaySummaryBar(player: _player, record: widget.record),
                const SizedBox(height: 8),
                Expanded(child: _tableArea(game)),
                ReplayControls(player: _player),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: panelWidth,
            child: ReplayShotList(player: _player, record: widget.record),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow(ReplayGame game, BoxConstraints constraints) {
    // 低于此高度时逐杆条会把球台压扁，改为抽屉查看。
    final showList = constraints.maxHeight >= 560;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Column(
        children: [
          ReplaySummaryBar(player: _player, record: widget.record, compact: true),
          const SizedBox(height: 8),
          Expanded(child: _tableArea(game)),
          const SizedBox(height: 6),
          ReplayControls(player: _player, compact: true),
          if (showList) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 108,
              child: ReplayShotList(player: _player, record: widget.record, horizontal: true),
            ),
          ],
        ],
      ),
    );
  }

  /// 球台占满剩余空间，并保持球台比例居中。
  Widget _tableArea(ReplayGame game) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = TableLayout.fit(constraints.biggest);
        return Center(child: _buildTable(game, size));
      },
    );
  }

  Widget _buildTable(ReplayGame game, Size size) {
    return SizedBox(
      key: const Key('replay-table'),
      width: size.width,
      height: size.height,
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
              child: ReplayShotOverlay(player: _player),
            ),
          ),
        ],
      ),
    );
  }
}
