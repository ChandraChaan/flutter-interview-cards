import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/preferences.dart';
import '../domain/progress_repository.dart';
import '../domain/study_progress.dart';

/// Keeps progress on the device as one JSON value in shared preferences.
final class PrefsProgressRepository implements ProgressRepository {
  const PrefsProgressRepository(this._prefs);

  static const key = 'progress.v1';

  final SharedPreferences _prefs;

  @override
  Future<StudyProgress> load() async {
    final source = _prefs.getString(key);
    if (source == null) return StudyProgress.empty;
    try {
      return decodeProgress(source);
    } on Object catch (error, stack) {
      // Unreadable progress shouldn't lock anyone out of studying. Start
      // fresh, but keep the old value under another key so it isn't lost.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'progress',
          context: ErrorDescription('while reading saved progress'),
        ),
      );
      await _prefs.setString('$key.unreadable', source);
      return StudyProgress.empty;
    }
  }

  @override
  Future<void> save(StudyProgress progress) =>
      _prefs.setString(key, encodeProgress(progress));

  @override
  Future<void> clear() => _prefs.remove(key);
}

String encodeProgress(StudyProgress progress) => jsonEncode({
  'cards': {
    for (final card in progress.cards.values)
      card.cardId: {
        'reps': card.reps,
        'lapses': card.lapses,
        'interval': card.intervalDays,
        'ease': card.ease,
        'due': card.due.toUtc().toIso8601String(),
        'last': card.lastReviewed.toUtc().toIso8601String(),
      },
  },
  'reviewsByDay': progress.reviewsByDay,
  'newCardsByDay': progress.newCardsByDay,
});

StudyProgress decodeProgress(String source) {
  final json = jsonDecode(source) as Map<String, Object?>;
  final cards = json['cards']! as Map<String, Object?>;
  return StudyProgress(
    cards: {
      for (final MapEntry(:key, :value) in cards.entries)
        key: _card(key, value! as Map<String, Object?>),
    },
    reviewsByDay: _counts(json['reviewsByDay']),
    newCardsByDay: _counts(json['newCardsByDay']),
  );
}

CardProgress _card(String id, Map<String, Object?> json) => CardProgress(
  cardId: id,
  reps: json['reps']! as int,
  lapses: json['lapses']! as int,
  intervalDays: json['interval']! as int,
  ease: (json['ease']! as num).toDouble(),
  due: DateTime.parse(json['due']! as String).toUtc(),
  lastReviewed: DateTime.parse(json['last']! as String).toUtc(),
);

Map<String, int> _counts(Object? json) => {
  if (json case final Map<String, Object?> map)
    for (final MapEntry(:key, :value) in map.entries) key: value! as int,
};

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => PrefsProgressRepository(ref.watch(sharedPreferencesProvider)),
);
