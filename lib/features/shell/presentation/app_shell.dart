import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/links.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/theme_mode_controller.dart';

/// The top-level tabs, in navigation order.
const shellPaths = ['/', '/browse', '/progress'];

/// App bar plus navigation: a bottom bar on phones, a rail on wider screens.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = shellPaths.indexOf(location).clamp(0, shellPaths.length - 1);
    void onSelected(int i) => context.go(shellPaths[i]);
    final destinations = [
      (Icons.school_outlined, Icons.school, l10n.navStudy),
      (Icons.search, Icons.search, l10n.navBrowse),
      (Icons.insights_outlined, Icons.insights, l10n.navProgress),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: const [_ThemeButton(), _HandbookButton(), SizedBox(width: 8)],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: onSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (icon, selected, label) in destinations)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: onSelected,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
    );
  }
}

class _ThemeButton extends ConsumerWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final (icon, tooltip) = switch (mode) {
      ThemeMode.system => (Icons.brightness_auto_outlined, l10n.themeSystem),
      ThemeMode.light => (Icons.light_mode_outlined, l10n.themeLight),
      ThemeMode.dark => (Icons.dark_mode_outlined, l10n.themeDark),
    };
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: ref.read(themeModeProvider.notifier).cycle,
    );
  }
}

class _HandbookButton extends StatelessWidget {
  const _HandbookButton();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).theHandbook,
    icon: const Icon(Icons.menu_book_outlined),
    onPressed: () => launchUrl(handbookUrl),
  );
}
