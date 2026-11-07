import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/match_record.dart';
import '../core/replay_player.dart';
import '../flame/replay_game.dart';
import '../flame/table_layout.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import 'widgets/replay_controls.dart';
import 'widgets/replay_shot_list.dart';
import 'widgets/replay_shot_overlay.dart';
import 'widgets/replay_summary_bar.dart';

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
    _game = ReplayGame(player: _player, settings: context.read<SettingsProvider>());
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
              final wide = constraints.maxWidth >= 900 && constraints.maxHeight >= 520;
              return wide ? _buildWide(game, constraints) : _buildNarrow(game, constraints);
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
                ReplaySummaryBar(player: _player, record: widget.record),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: _buildTable(
                      game,
                      Size(constraints.maxWidth - 360, constraints.maxHeight - 150),
                    ),
                  ),
                ),
                ReplayControls(player: _player),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 320,
            child: ReplayShotList(player: _player, record: widget.record),
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
          ReplaySummaryBar(player: _player, record: widget.record, compact: true),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: _buildTable(game, Size(constraints.maxWidth, constraints.maxHeight - 268)),
            ),
          ),
          const SizedBox(height: 6),
          ReplayControls(player: _player, compact: true),
          const SizedBox(height: 4),
          SizedBox(
            height: 118,
            child: ReplayShotList(player: _player, record: widget.record, horizontal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(ReplayGame game, Size available) {
    final size = TableLayout.fit(available);
    return SizedBox(
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
