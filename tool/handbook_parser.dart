/// Turns the Flutter Architect Handbook's chapter Markdown into flashcards.
///
/// Each chapter file looks like this:
///
/// ```md
/// # 1. Dart essentials
/// ...navigation and intro...
/// ---
/// ### 🟢 Question
/// Answer in Markdown, until the next `###` or the closing `---`.
/// ```
library;

/// The handbook's three levels, in the order the handbook lists them.
enum ParsedLevel {
  junior('🟢'),
  senior('🟡'),
  architect('🔴');

  const ParsedLevel(this.emoji);

  final String emoji;
}

class ParsedCard {
  const ParsedCard({
    required this.id,
    required this.chapterId,
    required this.level,
    required this.question,
    required this.answer,
    required this.anchor,
  });

  /// Stable, URL-safe ID: the GitHub heading anchor without its leading `-`.
  final String id;
  final String chapterId;
  final ParsedLevel level;

  /// The question as written in the heading, without the level emoji.
  final String question;

  /// The answer as Markdown, code blocks included.
  final String answer;

  /// The heading's anchor on GitHub, e.g. `-final-vs-const-vs-late`.
  final String anchor;

  Map<String, Object?> toJson() => {
    'id': id,
    'chapter': chapterId,
    'level': level.name,
    'question': question,
    'answer': answer,
    'anchor': anchor,
  };
}

class ParsedChapter {
  const ParsedChapter({
    required this.id,
    required this.number,
    required this.title,
    required this.path,
    required this.cards,
  });

  final String id;
  final int number;
  final String title;

  /// Path inside the handbook repository, e.g. `chapters/01-dart.md`.
  final String path;
  final List<ParsedCard> cards;

  Map<String, Object?> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'path': path,
  };
}

final _fileName = RegExp(r'^(\d+)-([a-z0-9-]+)\.md$');
final _chapterTitle = RegExp(r'^#\s+\d+\.\s+(.+)$');
final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Parses one chapter. [path] is relative to the handbook root
/// (`chapters/01-dart.md`); its file name gives the chapter number and ID.
///
/// Throws a [FormatException] naming the file and line when the Markdown
/// doesn't follow the handbook's format, so a broken import fails loudly.
ParsedChapter parseChapter({required String path, required String markdown}) {
  final fileName = path.split('/').last;
  final nameMatch = _fileName.firstMatch(fileName);
  if (nameMatch == null) {
    throw FormatException('$path: expected a name like "01-dart.md"');
  }
  final number = int.parse(nameMatch.group(1)!);
  final chapterId = nameMatch.group(2)!;

  String? title;
  final cards = <ParsedCard>[];
  final anchorCounts = <String, int>{};

  ParsedLevel? level;
  String? heading;
  final answer = <String>[];
  var inFence = false;

  void closeCard() {
    if (heading == null) return;
    final text = _trimBlankLines(answer).join('\n');
    if (text.isEmpty) {
      throw FormatException('$path: "$heading" has no answer');
    }
    var anchor = githubAnchor('${level!.emoji} $heading');
    final seen = anchorCounts[anchor] ?? 0;
    anchorCounts[anchor] = seen + 1;
    if (seen > 0) anchor = '$anchor-$seen';
    cards.add(
      ParsedCard(
        id: anchor.replaceFirst(RegExp('^-+'), ''),
        chapterId: chapterId,
        level: level!,
        question: heading!,
        answer: text,
        anchor: anchor,
      ),
    );
    heading = null;
    level = null;
    answer.clear();
  }

  final lines = markdown.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('```')) inFence = !inFence;

    if (!inFence && title == null && line.startsWith('# ')) {
      final match = _chapterTitle.firstMatch(line);
      if (match == null) {
        throw FormatException('$path:${i + 1}: expected "# <n>. <Title>"');
      }
      title = match.group(1)!.trim();
    } else if (!inFence && line.startsWith('### ')) {
      closeCard();
      final rest = line.substring(4).trim();
      for (final candidate in ParsedLevel.values) {
        if (rest.startsWith('${candidate.emoji} ')) {
          level = candidate;
          heading = rest.substring(candidate.emoji.length).trim();
        }
      }
      if (heading == null) {
        throw FormatException(
          '$path:${i + 1}: a question must start with 🟢, 🟡 or 🔴',
        );
      }
    } else if (!inFence && line.trim() == '---') {
      // A rule closes the intro and, after the last question, the chapter.
      closeCard();
    } else if (heading != null) {
      answer.add(line);
    }
  }
  if (inFence) throw FormatException('$path: unclosed code block');
  closeCard();

  if (title == null) throw FormatException('$path: missing "# " title');
  if (cards.isEmpty) throw FormatException('$path: no questions found');
  return ParsedChapter(
    id: chapterId,
    number: number,
    title: title,
    path: path,
    cards: cards,
  );
}

/// The anchor GitHub generates for a Markdown heading: lower case, spaces to
/// `-`, and everything except letters, digits, `-` and `_` dropped (so the
/// level emoji leaves a leading `-`).
String githubAnchor(String heading) {
  final buffer = StringBuffer();
  for (final char in heading.trim().toLowerCase().runes.map(
    String.fromCharCode,
  )) {
    if (char == ' ') {
      buffer.write('-');
    } else if (char == '-' || char == '_' || _letterOrDigit.hasMatch(char)) {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

/// Builds the JSON asset the app loads. Throws if two cards share an ID.
Map<String, Object?> buildDeckJson({
  required String repository,
  required String commit,
  required List<ParsedChapter> chapters,
}) {
  final sorted = [...chapters]..sort((a, b) => a.number.compareTo(b.number));
  final ids = <String>{};
  for (final card in sorted.expand((c) => c.cards)) {
    if (!ids.add(card.id)) {
      throw FormatException('Two questions share the ID "${card.id}"');
    }
  }
  return {
    'source': {'repository': repository, 'commit': commit},
    'chapters': [for (final chapter in sorted) chapter.toJson()],
    'cards': [
      for (final chapter in sorted)
        for (final card in chapter.cards) card.toJson(),
    ],
  };
}

List<String> _trimBlankLines(List<String> lines) {
  var start = 0;
  var end = lines.length;
  while (start < end && lines[start].trim().isEmpty) {
    start++;
  }
  while (end > start && lines[end - 1].trim().isEmpty) {
    end--;
  }
  return lines.sublist(start, end);
}
