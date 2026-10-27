import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/handbook_parser.dart';

const _handbook = 'third_party/flutter-architect-handbook';

List<ParsedChapter> _parseHandbook() {
  final dir = Directory('$_handbook/chapters');
  if (!dir.existsSync()) {
    fail('Handbook submodule missing. Run: git submodule update --init');
  }
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final file in files)
      parseChapter(
        path: 'chapters/${file.uri.pathSegments.last}',
        markdown: file.readAsStringSync(),
      ),
  ];
}

void main() {
  group('the pinned handbook', () {
    late final chapters = _parseHandbook();
    late final cards = chapters.expand((c) => c.cards).toList();

    test('has 67 questions in 10 chapters', () {
      expect(chapters, hasLength(10));
      expect(cards, hasLength(67));
      expect(chapters.map((c) => c.number), [for (var i = 1; i <= 10; i++) i]);
      expect(chapters.first.title, 'Dart essentials');
      expect(chapters.first.id, 'dart');
    });

    test('levels match the counts in the handbook README', () {
      int count(ParsedLevel level) =>
          cards.where((c) => c.level == level).length;
      expect(count(ParsedLevel.junior), 16);
      expect(count(ParsedLevel.senior), 34);
      expect(count(ParsedLevel.architect), 17);
    });

    test('every card has a unique ID, a question and an answer', () {
      expect(cards.map((c) => c.id).toSet(), hasLength(cards.length));
      for (final card in cards) {
        expect(card.id, matches(RegExp(r'^[a-z0-9_-]+$')), reason: card.id);
        expect(card.anchor, '-${card.id}');
        expect(card.question, isNot(startsWith('🟢')));
        expect(card.answer, isNot(contains('\n### ')));
        expect(card.answer.trim(), card.answer);
        // The chapter footer navigation never leaks into the last answer.
        expect(card.answer, isNot(contains('Contents')), reason: card.id);
      }
    });

    test('keeps code blocks intact', () {
      final isolates = cards.firstWhere(
        (c) =>
            c.id ==
            'when-do-you-need-an-isolate-and-whats-the-cheapest-way-'
                'to-use-one',
      );
      expect(isolates.level, ParsedLevel.senior);
      expect(
        isolates.answer,
        contains(
          '```dart\n'
          'final articles = await Isolate.run(() => '
          'parseArticles(hugeJsonString));\n'
          '```',
        ),
      );
      final withCode = cards.where((c) => c.answer.contains('```')).toList();
      expect(withCode, isNotEmpty);
      for (final card in withCode) {
        expect('```'.allMatches(card.answer).length.isEven, isTrue);
      }
    });

    test('assets/cards.json is up to date', () {
      final asset =
          jsonDecode(File('assets/cards.json').readAsStringSync())
              as Map<String, Object?>;
      final expected =
          jsonDecode(
                jsonEncode(
                  buildDeckJson(
                    repository: 'ChandraChaan/flutter-architect-handbook',
                    commit: 'ignored',
                    chapters: chapters,
                  ),
                ),
              )
              as Map<String, Object?>;
      expect(asset['chapters'], expected['chapters']);
      expect(
        asset['cards'],
        expected['cards'],
        reason: 'Run: dart run tool/import_handbook.dart',
      );
    });
  });

  group('parseChapter', () {
    const sample = '''
# 3. Sample chapter

[← Contents](../README.md)

---

### 🟢 First `question`?

Answer one.

```dart
// ### not a heading inside code
final x = 1;
```

### 🔴 Second question?

- a
- b

---

[← Contents](../README.md)
''';

    test('splits questions and drops the intro and footer', () {
      final chapter = parseChapter(
        path: 'chapters/03-sample.md',
        markdown: sample,
      );
      expect(chapter.number, 3);
      expect(chapter.id, 'sample');
      expect(chapter.title, 'Sample chapter');
      expect(chapter.cards, hasLength(2));
      final first = chapter.cards.first;
      expect(first.question, 'First `question`?');
      expect(first.level, ParsedLevel.junior);
      expect(first.id, 'first-question');
      expect(first.answer, startsWith('Answer one.'));
      expect(first.answer, contains('// ### not a heading inside code'));
      expect(first.answer, endsWith('```'));
      expect(chapter.cards.last.level, ParsedLevel.architect);
      expect(chapter.cards.last.answer, '- a\n- b');
    });

    test('rejects a question without a level', () {
      expect(
        () => parseChapter(
          path: 'chapters/01-x.md',
          markdown: '# 1. X\n\n---\n\n### No level?\n\nAnswer\n',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('chapters/01-x.md:5'),
          ),
        ),
      );
    });

    test('rejects an unclosed code block', () {
      expect(
        () => parseChapter(
          path: 'chapters/01-x.md',
          markdown: '# 1. X\n\n### 🟢 Q?\n\n```dart\ncode\n',
        ),
        throwsFormatException,
      );
    });

    test('numbers repeated headings the way GitHub does', () {
      final chapter = parseChapter(
        path: 'chapters/01-x.md',
        markdown: '# 1. X\n\n### 🟢 Same?\n\nA\n\n### 🟡 Same?\n\nB\n',
      );
      expect(chapter.cards.map((c) => c.anchor), ['-same', '-same-1']);
    });
  });

  test('githubAnchor matches the anchors GitHub generates', () {
    expect(
      githubAnchor('🟢 What does sound null safety actually guarantee?'),
      '-what-does-sound-null-safety-actually-guarantee',
    );
    expect(
      githubAnchor('🟢 `final` vs `const` vs `late`?'),
      '-final-vs-const-vs-late',
    );
    expect(
      githubAnchor('🟡 `Future` vs `Stream` vs `Stream.asBroadcastStream`?'),
      '-future-vs-stream-vs-streamasbroadcaststream',
    );
    expect(
      githubAnchor(
        "🟡 When do you need an isolate, and what's the cheapest way to use one?",
      ),
      '-when-do-you-need-an-isolate-and-whats-the-cheapest-way-to-use-one',
    );
  });

  test('buildDeckJson rejects duplicate IDs across chapters', () {
    ParsedChapter chapter(int n) => parseChapter(
      path: 'chapters/0$n-c$n.md',
      markdown: '# $n. C\n\n### 🟢 Same?\n\nA\n',
    );
    expect(
      () => buildDeckJson(
        repository: 'r',
        commit: 'c',
        chapters: [chapter(1), chapter(2)],
      ),
      throwsFormatException,
    );
  });
}
