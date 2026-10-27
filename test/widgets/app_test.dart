import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_interview_cards/app.dart';
import 'package:flutter_interview_cards/core/clock.dart';
import 'package:flutter_interview_cards/core/preferences.dart';
import 'package:flutter_interview_cards/core/router.dart';
import 'package:flutter_interview_cards/features/deck/data/asset_deck_repository.dart';
import 'package:flutter_interview_cards/features/progress/presentation/progress_screen.dart';
import 'package:flutter_interview_cards/features/review/data/prefs_progress_repository.dart';
import 'package:flutter_interview_cards/features/review/domain/study_progress.dart';
import 'package:flutter_interview_cards/features/review/presentation/progress_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

final _now = DateTime(2026, 3, 10, 12).toUtc();

/// Pumps the whole app with a small deck, empty storage and a fixed clock.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  FakeDeckRepository? deck,
  Size size = const Size(1000, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      deckRepositoryProvider.overrideWithValue(deck ?? FakeDeckRepository()),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const InterviewCardsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Finder _text(String text) => find.textContaining(text, findRichText: true);

void main() {
  group('study', () {
    testWidgets('show the answer, grade it, and move to the next card', (
      tester,
    ) async {
      final container = await pumpApp(tester);

      expect(_text('Question 0'), findsOneWidget);
      expect(_text('Answer 0'), findsNothing);
      expect(_text('4 cards left today'), findsOneWidget);

      await tester.tap(find.byKey(const Key('show-answer')));
      await tester.pumpAndSettle();
      expect(_text('Answer 0'), findsOneWidget);
      expect(_text('final x0 = 0;'), findsOneWidget, reason: 'code block');
      // A new card's next review for each grade.
      expect(find.bySemanticsLabel('Again, today'), findsOneWidget);
      expect(find.bySemanticsLabel('Good, 2 days'), findsOneWidget);
      expect(find.bySemanticsLabel('Easy, 4 days'), findsOneWidget);

      await tester.tap(find.byKey(const Key('grade-good')));
      await tester.pumpAndSettle();

      expect(_text('Question 1'), findsOneWidget);
      expect(_text('Answer 1'), findsNothing);
      expect(_text('3 cards left today'), findsOneWidget);
      expect(_text('1-day streak'), findsOneWidget);

      final saved = await container.read(progressRepositoryProvider).load();
      expect(saved.cards['card-0']!.intervalDays, 2);
    });

    testWidgets('keyboard: space shows the answer, 1–4 grade', (tester) async {
      await pumpApp(tester);

      // Grading before the answer is shown does nothing.
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();
      expect(_text('Question 0'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_text('Answer 0'), findsOneWidget);

      // "Again" keeps the card in today's queue, behind nothing new.
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(_text('4 cards left today'), findsOneWidget);
      expect(_text('Question 0'), findsOneWidget);
      expect(_text('Answer 0'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pumpAndSettle();
      expect(_text('Question 1'), findsOneWidget);
      expect(_text('3 cards left today'), findsOneWidget);
    });

    testWidgets('finishing the queue shows the done screen', (tester) async {
      await pumpApp(tester, size: const Size(390, 844));
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('show-answer')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('grade-easy')));
        await tester.pumpAndSettle();
      }
      expect(_text('All done for today'), findsOneWidget);
      expect(_text('You reviewed 4 cards today'), findsOneWidget);

      await tester.tap(_text('See your progress'));
      await tester.pumpAndSettle();
      expect(_text('Mastery by chapter'), findsOneWidget);
      expect(_text('0 mastered · 2 learning · 0 new'), findsNWidgets(2));
    });

    testWidgets('a failed load offers a retry', (tester) async {
      final deck = FakeDeckRepository()..fail = true;
      await pumpApp(tester, deck: deck);
      expect(_text("Couldn't load the cards."), findsOneWidget);

      deck.fail = false;
      await tester.tap(_text('Try again'));
      await tester.pumpAndSettle();
      expect(_text('Question 0'), findsOneWidget);
    });
  });

  testWidgets('focusing on a chapter limits the queue and is remembered', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    expect(_text('Focus: all cards'), findsOneWidget);

    await tester.tap(find.byKey(const Key('focus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('focus-ui')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focus-done')));
    await tester.pumpAndSettle();

    expect(_text('Focus: 1 chapter · all levels'), findsOneWidget);
    expect(_text('2 cards left today'), findsOneWidget);
    expect(_text('Question 2'), findsOneWidget);

    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('settings.studyFocus'), contains('ui'));

    // Keyboard shortcuts still work after the sheet closes.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(_text('Answer 2'), findsOneWidget);
  });

  group('deep links', () {
    testWidgets('#/card/<id> opens that card', (tester) async {
      final container = await pumpApp(tester);
      container.read(routerProvider).go('/card/card-2');
      await tester.pumpAndSettle();

      expect(_text('Question 2'), findsOneWidget);
      expect(_text('2. UI'), findsOneWidget);
      expect(find.byTooltip('Read this in the handbook'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_text('Answer 2'), findsOneWidget);
    });

    testWidgets('an unknown card ID shows a friendly message', (tester) async {
      final container = await pumpApp(tester);
      container.read(routerProvider).go('/card/does-not-exist');
      await tester.pumpAndSettle();
      expect(_text('Card not found'), findsOneWidget);
    });

    testWidgets('copying a link puts the card URL on the clipboard', (
      tester,
    ) async {
      final copied = <String>[];
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        },
      );
      final container = await pumpApp(tester);
      container.read(routerProvider).go('/card/card-1');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Copy a link to this card'));
      await tester.pumpAndSettle();
      expect(copied, [
        'https://chandrachaan.github.io/flutter-interview-cards/#/card/card-1',
      ]);
      expect(_text('Link copied'), findsOneWidget);
    });
  });

  group('browse', () {
    testWidgets('search and level filters narrow the list', (tester) async {
      final container = await pumpApp(tester);
      container.read(routerProvider).go('/browse');
      await tester.pumpAndSettle();
      expect(_text('4 cards'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search')), 'topic3');
      await tester.pumpAndSettle();
      expect(_text('1 card'), findsOneWidget);
      expect(_text('Question 3'), findsOneWidget);

      await tester.tap(_text('Clear filters'));
      await tester.pumpAndSettle();
      expect(_text('4 cards'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Senior'));
      await tester.pumpAndSettle();
      expect(_text('2 cards'), findsOneWidget);
      expect(_text('Question 0'), findsNothing);

      await tester.tap(_text('Question 2'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toggle-answer')), findsOneWidget);
    });
  });

  testWidgets('reset clears progress after confirming', (tester) async {
    final container = await pumpApp(tester);
    await container
        .read(progressControllerProvider.notifier)
        .grade('card-0', Grade.good);
    container.read(routerProvider).go('/progress');
    await tester.pumpAndSettle();
    expect(_text('0 mastered · 1 learning · 1 new'), findsOneWidget);
    // Half of chapter 1 is being learned, so half its bar is filled.
    final segment = tester.getSize(find.byKey(const Key('learning-segment')));
    final bar = tester.getSize(find.byType(MasteryBar).first);
    expect(segment.height, bar.height);
    expect(segment.width, closeTo(bar.width / 2, 1));

    await tester.scrollUntilVisible(
      find.byKey(const Key('reset-progress')),
      200,
    );
    await tester.tap(find.byKey(const Key('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-reset')));
    await tester.pumpAndSettle();

    expect(_text('Progress reset'), findsOneWidget);
    expect(_text('0 mastered · 0 learning · 2 new'), findsNWidgets(2));
    expect(
      (await container.read(progressRepositoryProvider).load()).cards,
      isEmpty,
    );
  });
}
