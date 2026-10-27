import 'package:flutter/foundation.dart';
import 'package:flutter_interview_cards/features/review/data/prefs_progress_repository.dart';
import 'package:flutter_interview_cards/features/review/domain/scheduler.dart';
import 'package:flutter_interview_cards/features/review/domain/study_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<PrefsProgressRepository> repository([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsProgressRepository(await SharedPreferences.getInstance());
  }

  test('loads empty progress when nothing is saved', () async {
    expect(await (await repository()).load(), StudyProgress.empty);
  });

  test('round-trips progress through shared preferences', () async {
    const scheduler = Scheduler();
    var progress = StudyProgress.empty;
    final now = DateTime.utc(2026, 5, 4, 9, 30);
    for (final (id, grade) in [
      ('a', Grade.good),
      ('b', Grade.again),
      ('a', Grade.easy),
      ('c', Grade.hard),
    ]) {
      progress = scheduler.review(
        progress: progress,
        cardId: id,
        grade: grade,
        now: now,
      );
    }

    final repo = await repository();
    await repo.save(progress);
    final prefs = await SharedPreferences.getInstance();
    final reloaded = await PrefsProgressRepository(prefs).load();

    expect(reloaded, progress);
    expect(reloaded.cards['a']!.ease, progress.cards['a']!.ease);
    expect(reloaded.cards['a']!.due.isUtc, isTrue);
    expect(reloaded.reviewsByDay.values.single, 4);
    expect(reloaded.newCardsByDay.values.single, 3);
  });

  test('clear forgets everything', () async {
    final repo = await repository();
    await repo.save(StudyProgress(reviewsByDay: const {'2026-01-01': 1}));
    await repo.clear();
    expect(await repo.load(), StudyProgress.empty);
  });

  test('unreadable progress starts fresh but keeps a backup', () async {
    final repo = await repository({PrefsProgressRepository.key: '{"cards": 4'});
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    expect(await repo.load(), StudyProgress.empty);
    expect(errors, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('${PrefsProgressRepository.key}.unreadable'),
      '{"cards": 4',
    );
  });
}
