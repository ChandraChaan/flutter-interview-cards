// Generates assets/cards.json from the Flutter Architect Handbook.
//
//   dart run tool/import_handbook.dart          # regenerate the asset
//   dart run tool/import_handbook.dart --check  # fail if it's out of date
//
// The handbook is pinned as a git submodule in third_party/; to import a newer
// version, check out that commit in the submodule and run this again.
import 'dart:convert';
import 'dart:io';

import 'handbook_parser.dart';

const _repository = 'ChandraChaan/flutter-architect-handbook';
const _defaultHandbook = 'third_party/flutter-architect-handbook';
const _defaultOutput = 'assets/cards.json';

void main(List<String> args) {
  final check = args.contains('--check');
  final handbook = _option(args, '--handbook') ?? _defaultHandbook;
  final output = _option(args, '--out') ?? _defaultOutput;

  final chaptersDir = Directory('$handbook/chapters');
  if (!chaptersDir.existsSync()) {
    stderr.writeln(
      'No chapters in $handbook. Run: git submodule update --init',
    );
    exit(2);
  }

  final files =
      chaptersDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final chapters = [
    for (final file in files)
      parseChapter(
        path: 'chapters/${file.uri.pathSegments.last}',
        markdown: file.readAsStringSync(),
      ),
  ];

  final deck = buildDeckJson(
    repository: _repository,
    commit: _commitOf(handbook),
    chapters: chapters,
  );
  final json = '${const JsonEncoder.withIndent('  ').convert(deck)}\n';
  final cardCount = chapters.fold(0, (sum, c) => sum + c.cards.length);

  final outFile = File(output);
  if (check) {
    if (!outFile.existsSync() || outFile.readAsStringSync() != json) {
      stderr.writeln(
        '$output is out of date with the handbook. '
        'Run: dart run tool/import_handbook.dart',
      );
      exit(1);
    }
    stdout.writeln('$output is up to date ($cardCount cards).');
    return;
  }
  outFile
    ..createSync(recursive: true)
    ..writeAsStringSync(json);
  stdout.writeln(
    'Wrote $cardCount cards from ${chapters.length} chapters to $output.',
  );
}

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

String _commitOf(String handbook) {
  final result = Process.runSync('git', ['-C', handbook, 'rev-parse', 'HEAD']);
  if (result.exitCode != 0) {
    stderr.writeln('Could not read the handbook commit: ${result.stderr}');
    exit(2);
  }
  return (result.stdout as String).trim();
}
