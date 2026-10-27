import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Light, dark or follow the system; remembered on the device.
class ThemeModeController extends Notifier<ThemeMode> {
  static const key = 'settings.themeMode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  /// System → light → dark → system.
  Future<void> cycle() async {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await ref.read(sharedPreferencesProvider).setString(key, state.name);
  }
}
