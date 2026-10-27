// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Interview Cards';

  @override
  String get navStudy => 'Study';

  @override
  String get navBrowse => 'Browse';

  @override
  String get navProgress => 'Progress';

  @override
  String get themeSystem => 'Theme: follow system (tap for light)';

  @override
  String get themeLight => 'Theme: light (tap for dark)';

  @override
  String get themeDark => 'Theme: dark (tap to follow system)';

  @override
  String get theHandbook => 'The handbook';

  @override
  String get sourceCode => 'Source code';

  @override
  String get loadError => 'Couldn\'t load the cards.';

  @override
  String get retry => 'Try again';

  @override
  String chapterLabel(int number, String title) {
    return '$number. $title';
  }

  @override
  String get copyLink => 'Copy a link to this card';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get openInHandbook => 'Read this in the handbook';

  @override
  String get levelJunior => 'Junior';

  @override
  String get levelSenior => 'Senior';

  @override
  String get levelArchitect => 'Architect';

  @override
  String cardsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards left today',
      one: '1 card left today',
    );
    return '$_temp0';
  }

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day streak',
      one: '1-day streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String get showAnswer => 'Show answer';

  @override
  String get hideAnswer => 'Hide answer';

  @override
  String get keyboardHint => 'Space to show the answer · 1–4 to grade';

  @override
  String get gradeAgain => 'Again';

  @override
  String get gradeHard => 'Hard';

  @override
  String get gradeGood => 'Good';

  @override
  String get gradeEasy => 'Easy';

  @override
  String nextReview(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String withShortcut(int key, String label) {
    return '$key · $label';
  }

  @override
  String get doneTitle => 'All done for today';

  @override
  String doneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You reviewed $count cards today. Come back tomorrow to keep your streak going.',
      one:
          'You reviewed 1 card today. Come back tomorrow to keep your streak going.',
      zero:
          'Nothing is due right now. Browse the cards, or come back tomorrow for new ones.',
    );
    return '$_temp0';
  }

  @override
  String get browseCards => 'Browse all cards';

  @override
  String get seeProgress => 'See your progress';

  @override
  String get studyToday => 'Study today\'s cards';

  @override
  String get searchHint => 'Search questions and answers';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get chapter => 'Chapter';

  @override
  String get allChapters => 'All chapters';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
      zero: 'No cards match',
    );
    return '$_temp0';
  }

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get statusNew => 'New';

  @override
  String get statusLearning => 'Learning';

  @override
  String get statusMastered => 'Mastered';

  @override
  String get cardNotFoundTitle => 'Card not found';

  @override
  String get cardNotFoundBody =>
      'This link doesn\'t match any question in the handbook. The question may have been reworded.';

  @override
  String get statStreak => 'Day streak';

  @override
  String get statReviewedToday => 'Reviewed today';

  @override
  String get statDueToday => 'Left today';

  @override
  String get statMastered => 'Mastered';

  @override
  String ofTotal(int count, int total) {
    return '$count / $total';
  }

  @override
  String get masteryTitle => 'Mastery by chapter';

  @override
  String masteryExplainer(int days) {
    return 'A card is mastered once its next review is at least $days days away.';
  }

  @override
  String masteryBreakdown(int mastered, int learning, int fresh) {
    return '$mastered mastered · $learning learning · $fresh new';
  }

  @override
  String get aboutTitle => 'About these cards';

  @override
  String get aboutBody =>
      'Every card is a question from the Flutter Architect Handbook, a free, MIT-licensed guide from junior developer to architect. Your progress stays on this device.';

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetTitle => 'Reset all progress?';

  @override
  String get resetBody =>
      'This forgets every review and your streak on this device. It can\'t be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get resetDone => 'Progress reset';

  @override
  String get focusAll => 'Focus: all cards';

  @override
  String focusSome(String chapters, String levels) {
    return 'Focus: $chapters · $levels';
  }

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String get allLevels => 'all levels';

  @override
  String get focusTitle => 'Focus today\'s cards';

  @override
  String get focusExplainer =>
      'Pick the chapters and levels to study, for example to prepare for a senior interview. Leave a group empty to include all of it.';

  @override
  String get levels => 'Levels';

  @override
  String get chapters => 'Chapters';

  @override
  String get studyEverything => 'Study everything';

  @override
  String get done => 'Done';

  @override
  String get changeFocus => 'Change focus';
}
