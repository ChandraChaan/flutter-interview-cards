import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences.dart';
import '../../deck/domain/flashcard.dart';
import '../domain/study_focus.dart';

final studyFocusProvider = NotifierProvider<StudyFocusController, StudyFocus>(
  StudyFocusController.new,
);

/// The chapters and levels you're focusing on; remembered on the device.
class StudyFocusController extends Notifier<StudyFocus> {
  static const key = 'settings.studyFocus';

  @override
  StudyFocus build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(key);
    if (saved == null) return StudyFocus.all;
    try {
      final json = jsonDecode(saved) as Map<String, Object?>;
      final levels = Level.values.asNameMap();
      return StudyFocus(
        chapterIds: {
          for (final id in json['chapters']! as List<Object?>) id! as String,
        },
        levels: {
          for (final name in json['levels']! as List<Object?>) ?levels[name],
        },
      );
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'study focus',
          context: ErrorDescription('while reading the saved study focus'),
        ),
      );
      return StudyFocus.all;
    }
  }

  Future<void> toggleChapter(String id) => _set(state.toggleChapter(id));

  Future<void> toggleLevel(Level level) => _set(state.toggleLevel(level));

  Future<void> clear() => _set(StudyFocus.all);

  Future<void> _set(StudyFocus focus) async {
    state = focus;
    final prefs = ref.read(sharedPreferencesProvider);
    if (focus.isAll) {
      await prefs.remove(key);
    } else {
      await prefs.setString(
        key,
        jsonEncode({
          'chapters': focus.chapterIds.toList()..sort(),
          'levels': [for (final level in focus.levels) level.name]..sort(),
        }),
      );
    }
  }
}
