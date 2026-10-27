import 'package:flutter_interview_cards/core/preferences.dart';
import 'package:flutter_interview_cards/features/deck/domain/flashcard.dart';
import 'package:flutter_interview_cards/features/review/domain/study_focus.dart';
import 'package:flutter_interview_cards/features/review/presentation/study_focus_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  final cards = testDeck().cards;

  List<String> idsIn(StudyFocus focus) => [
    for (final card in cards.where(focus.includes)) card.id,
  ];

  test('an empty focus includes every card', () {
    expect(StudyFocus.all.isAll, isTrue);
    expect(idsIn(StudyFocus.all), hasLength(cards.length));
  });

  test('chapters and levels narrow the cards together', () {
    final ui = StudyFocus.all.toggleChapter('ui');
    expect(idsIn(ui), ['card-2', 'card-3']);
    expect(idsIn(ui.toggleLevel(Level.senior)), ['card-2']);
    expect(idsIn(StudyFocus.all.toggleLevel(Level.senior)), [
      'card-1',
      'card-2',
    ]);
    expect(ui.toggleChapter('ui'), StudyFocus.all);
  });

  group('StudyFocusController', () {
    Future<ProviderContainer> container([
      Map<String, Object> values = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      return ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    }

    test('remembers the focus across restarts', () async {
      final first = await container();
      final controller = first.read(studyFocusProvider.notifier);
      await controller.toggleChapter('ui');
      await controller.toggleLevel(Level.architect);

      final prefs = await SharedPreferences.getInstance();
      final second = ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(
        second.read(studyFocusProvider),
        const StudyFocus(chapterIds: {'ui'}, levels: {Level.architect}),
      );

      await second.read(studyFocusProvider.notifier).clear();
      expect(prefs.getString(StudyFocusController.key), isNull);
    });

    test('ignores levels it no longer knows', () async {
      final c = await container({
        StudyFocusController.key:
            '{"chapters": [], "levels": ["guru", "senior"]}',
      });
      expect(c.read(studyFocusProvider).levels, {Level.senior});
    });
  });
}
