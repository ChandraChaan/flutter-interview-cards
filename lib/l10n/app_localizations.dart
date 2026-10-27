import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Interview Cards'**
  String get appTitle;

  /// No description provided for @navStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get navStudy;

  /// No description provided for @navBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get navBrowse;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Theme: follow system (tap for light)'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Theme: light (tap for dark)'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Theme: dark (tap to follow system)'**
  String get themeDark;

  /// No description provided for @theHandbook.
  ///
  /// In en, this message translates to:
  /// **'The handbook'**
  String get theHandbook;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the cards.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @chapterLabel.
  ///
  /// In en, this message translates to:
  /// **'{number}. {title}'**
  String chapterLabel(int number, String title);

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy a link to this card'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @openInHandbook.
  ///
  /// In en, this message translates to:
  /// **'Read this in the handbook'**
  String get openInHandbook;

  /// No description provided for @levelJunior.
  ///
  /// In en, this message translates to:
  /// **'Junior'**
  String get levelJunior;

  /// No description provided for @levelSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior'**
  String get levelSenior;

  /// No description provided for @levelArchitect.
  ///
  /// In en, this message translates to:
  /// **'Architect'**
  String get levelArchitect;

  /// No description provided for @cardsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 card left today} other{{count} cards left today}}'**
  String cardsLeft(int count);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{No streak yet} =1{1-day streak} other{{days}-day streak}}'**
  String streakDays(int days);

  /// No description provided for @showAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get showAnswer;

  /// No description provided for @hideAnswer.
  ///
  /// In en, this message translates to:
  /// **'Hide answer'**
  String get hideAnswer;

  /// No description provided for @keyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Space to show the answer · 1–4 to grade'**
  String get keyboardHint;

  /// No description provided for @gradeAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get gradeAgain;

  /// No description provided for @gradeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get gradeHard;

  /// No description provided for @gradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get gradeGood;

  /// No description provided for @gradeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get gradeEasy;

  /// No description provided for @nextReview.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{1 day} other{{days} days}}'**
  String nextReview(int days);

  /// No description provided for @withShortcut.
  ///
  /// In en, this message translates to:
  /// **'{key} · {label}'**
  String withShortcut(int key, String label);

  /// No description provided for @doneTitle.
  ///
  /// In en, this message translates to:
  /// **'All done for today'**
  String get doneTitle;

  /// No description provided for @doneBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing is due right now. Browse the cards, or come back tomorrow for new ones.} =1{You reviewed 1 card today. Come back tomorrow to keep your streak going.} other{You reviewed {count} cards today. Come back tomorrow to keep your streak going.}}'**
  String doneBody(int count);

  /// No description provided for @browseCards.
  ///
  /// In en, this message translates to:
  /// **'Browse all cards'**
  String get browseCards;

  /// No description provided for @seeProgress.
  ///
  /// In en, this message translates to:
  /// **'See your progress'**
  String get seeProgress;

  /// No description provided for @studyToday.
  ///
  /// In en, this message translates to:
  /// **'Study today\'s cards'**
  String get studyToday;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search questions and answers'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapter;

  /// No description provided for @allChapters.
  ///
  /// In en, this message translates to:
  /// **'All chapters'**
  String get allChapters;

  /// No description provided for @resultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No cards match} =1{1 card} other{{count} cards}}'**
  String resultCount(int count);

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get statusLearning;

  /// No description provided for @statusMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get statusMastered;

  /// No description provided for @cardNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Card not found'**
  String get cardNotFoundTitle;

  /// No description provided for @cardNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This link doesn\'t match any question in the handbook. The question may have been reworded.'**
  String get cardNotFoundBody;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get statStreak;

  /// No description provided for @statReviewedToday.
  ///
  /// In en, this message translates to:
  /// **'Reviewed today'**
  String get statReviewedToday;

  /// No description provided for @statDueToday.
  ///
  /// In en, this message translates to:
  /// **'Left today'**
  String get statDueToday;

  /// No description provided for @statMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get statMastered;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} / {total}'**
  String ofTotal(int count, int total);

  /// No description provided for @masteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Mastery by chapter'**
  String get masteryTitle;

  /// No description provided for @masteryExplainer.
  ///
  /// In en, this message translates to:
  /// **'A card is mastered once its next review is at least {days} days away.'**
  String masteryExplainer(int days);

  /// No description provided for @masteryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{mastered} mastered · {learning} learning · {fresh} new'**
  String masteryBreakdown(int mastered, int learning, int fresh);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About these cards'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Every card is a question from the Flutter Architect Handbook, a free, MIT-licensed guide from junior developer to architect. Your progress stays on this device.'**
  String get aboutBody;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress?'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'This forgets every review and your streak on this device. It can\'t be undone.'**
  String get resetBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Progress reset'**
  String get resetDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
