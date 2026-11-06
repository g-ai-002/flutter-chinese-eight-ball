import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/match_controller.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'game_page.dart';
import 'help_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'widgets/entry_tile.dart';
import 'widgets/table_preview.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final entries = _entries(context, settings, colors);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF18211D), Color(0xFF0C110E)]
                : const [Color(0xFFF8F3E6), Color(0xFFE8EEDF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 620;
              final horizontal = constraints.maxWidth >= 900 ? 40.0 : 20.0;
              final contentWidth = math.min(
                constraints.maxWidth - horizontal * 2,
                760.0,
              );
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        _TopBar(darkMode: settings.darkMode),
                        const SizedBox(height: 18),
                        _Hero(skin: settings.tableSkin),
                        const SizedBox(height: 26),
                        if (twoColumns)
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final entry in entries)
                                SizedBox(
                                  width: (contentWidth - 12) / 2,
                                  child: entry,
                                ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              for (var i = 0; i < entries.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                entries[i],
                              ],
                            ],
                          ),
                        const SizedBox(height: 22),
                        Text(
                          'v${AppConstants.version} · 本地运行，无需联网',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _startGame(
    BuildContext context,
    SettingsProvider settings,
    GameMode mode,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          mode: mode,
          difficulty: settings.difficulty,
          humanSide: mode == GameMode.vsAi ? settings.humanSide : 0,
        ),
      ),
    );
  }

  List<Widget> _entries(
    BuildContext context,
    SettingsProvider settings,
    ColorScheme colors,
  ) => [
    EntryTile(
      leading: EntryBadge(
        icon: Icons.smart_toy_outlined,
        accent: colors.primary,
      ),
      title: GameMode.vsAi.label,
      subtitle: '三档 AI · 可先手或后手',
      onTap: () => _startGame(context, settings, GameMode.vsAi),
    ),
    EntryTile(
      leading: EntryBadge(
        icon: Icons.people_alt_outlined,
        accent: colors.tertiary,
      ),
      title: GameMode.twoPlayers.label,
      subtitle: '同屏轮流 · 面对面切磋',
      onTap: () => _startGame(context, settings, GameMode.twoPlayers),
    ),
    EntryTile(
      leading: EntryBadge(
        icon: Icons.adjust_outlined,
        accent: colors.secondary,
      ),
      title: GameMode.practice.label,
      subtitle: '任意摆球 · 重打同一杆',
      onTap: () => _startGame(context, settings, GameMode.practice),
    ),
    EntryTile(
      leading: EntryBadge(
        icon: Icons.movie_filter_outlined,
        accent: colors.primary,
      ),
      title: '最近对局',
      subtitle: '逐杆回放 · 复盘每一杆',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const HistoryPage())),
    ),
    EntryTile(
      leading: EntryBadge(
        icon: Icons.query_stats_outlined,
        accent: colors.tertiary,
      ),
      title: '数据统计',
      subtitle: '胜率 · 场均杆数 · 进球表现',
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const StatsPage())),
    ),
    EntryTile(
      leading: const EntryBadge(
        icon: Icons.menu_book_outlined,
        accent: appGold,
      ),
      title: '玩法规则',
      subtitle: '中式黑八规则与操作说明',
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const HelpPage())),
    ),
    EntryTile(
      leading: EntryBadge(icon: Icons.tune_outlined, accent: colors.secondary),
      title: '设置',
      subtitle: '球台配色 · 音效 · 偏好',
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
    ),
  ];
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.darkMode});

  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF17181A),
            shape: BoxShape.circle,
            border: Border.all(color: colors.outline),
          ),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F4E8),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '8',
              style: TextStyle(
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17181A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.appName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                AppConstants.appNameEn,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 1.2,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: darkMode ? '切换浅色' : '切换深色',
          onPressed: () => settings.setDarkMode(!darkMode),
          icon: Icon(
            darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
          icon: const Icon(Icons.settings_outlined, size: 21),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.skin});

  final TableSkin skin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        TablePreview(skin: skin),
        const SizedBox(height: 18),
        Text(
          '中式黑八',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 32,
            letterSpacing: 10,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OrnamentLine(color: colors.outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '落 袋 为 安',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 3,
                ),
              ),
            ),
            _OrnamentLine(color: colors.outline),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '一杆一世界，清台见真章',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OrnamentLine extends StatelessWidget {
  const _OrnamentLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 36, height: 1, color: color.withValues(alpha: 0.9));
  }
}
