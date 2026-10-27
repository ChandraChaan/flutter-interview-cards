import 'study_progress.dart';

abstract interface class ProgressRepository {
  /// Returns saved progress, or [StudyProgress.empty] when there is none.
  Future<StudyProgress> load();

  Future<void> save(StudyProgress progress);

  Future<void> clear();
}
