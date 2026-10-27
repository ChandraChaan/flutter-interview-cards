import 'package:flutter/material.dart';

import '../features/deck/domain/flashcard.dart';

const _seed = Color(0xFF3F51B5);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final base = ThemeData(colorScheme: scheme, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    extensions: [
      brightness == Brightness.light ? LevelColors.light : LevelColors.dark,
    ],
  );
}

/// Colours for the handbook's 🟢 🟡 🔴 levels. Always shown next to the
/// level's name, never on their own.
@immutable
class LevelColors extends ThemeExtension<LevelColors> {
  const LevelColors({
    required this.junior,
    required this.senior,
    required this.architect,
  });

  static const light = LevelColors(
    junior: Color(0xFF2E7D32),
    senior: Color(0xFFB26A00),
    architect: Color(0xFFC62828),
  );

  static const dark = LevelColors(
    junior: Color(0xFF81C784),
    senior: Color(0xFFFFCA6B),
    architect: Color(0xFFFF8A80),
  );

  final Color junior;
  final Color senior;
  final Color architect;

  Color of(Level level) => switch (level) {
    Level.junior => junior,
    Level.senior => senior,
    Level.architect => architect,
  };

  @override
  LevelColors copyWith({Color? junior, Color? senior, Color? architect}) =>
      LevelColors(
        junior: junior ?? this.junior,
        senior: senior ?? this.senior,
        architect: architect ?? this.architect,
      );

  @override
  LevelColors lerp(LevelColors? other, double t) {
    if (other == null) return this;
    return LevelColors(
      junior: Color.lerp(junior, other.junior, t)!,
      senior: Color.lerp(senior, other.senior, t)!,
      architect: Color.lerp(architect, other.architect, t)!,
    );
  }
}
