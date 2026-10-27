import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../data/prefs_progress_repository.dart';
import '../domain/scheduler.dart';
import '../domain/study_progress.dart';

final schedulerProvider = Provider<Scheduler>((ref) => const Scheduler());

final progressControllerProvider =
    AsyncNotifierProvider<ProgressController, StudyProgress>(
      ProgressController.new,
    );

/// Owns your saved progress: every review goes through [grade].
class ProgressController extends AsyncNotifier<StudyProgress> {
  @override
  Future<StudyProgress> build() => ref.watch(progressRepositoryProvider).load();

  Future<void> grade(String cardId, Grade grade) async {
    final current = await future;
    if (!ref.mounted) return;
    final next = ref
        .read(schedulerProvider)
        .review(
          progress: current,
          cardId: cardId,
          grade: grade,
          now: ref.read(clockProvider)(),
        );
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> reset() async {
    state = AsyncData(StudyProgress.empty);
    await ref.read(progressRepositoryProvider).clear();
  }

  Future<void> _save(StudyProgress progress) async {
    try {
      await ref.read(progressRepositoryProvider).save(progress);
    } on Object catch (error, stack) {
      // The review still counts for this session; it just won't survive a
      // reload. Report it rather than interrupting studying.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'progress',
          context: ErrorDescription('while saving progress'),
        ),
      );
    }
  }
}
