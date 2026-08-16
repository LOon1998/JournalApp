import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodSad;

  /// No description provided for @moodAwful.
  ///
  /// In en, this message translates to:
  /// **'Awful'**
  String get moodAwful;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @todayHeadline.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get todayHeadline;

  /// No description provided for @todayActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'What have you been up to?'**
  String get todayActivitiesTitle;

  /// No description provided for @activityWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get activityWork;

  /// No description provided for @activityFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get activityFamily;

  /// No description provided for @activityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get activityFriends;

  /// No description provided for @activityHobby.
  ///
  /// In en, this message translates to:
  /// **'Hobby'**
  String get activityHobby;

  /// No description provided for @activityExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get activityExercise;

  /// No description provided for @activitySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get activitySleep;

  /// No description provided for @activityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get activityOther;

  /// No description provided for @continueWriteJournal.
  ///
  /// In en, this message translates to:
  /// **'Continue & Write\nJournal'**
  String get continueWriteJournal;

  /// No description provided for @saveMoodOnly.
  ///
  /// In en, this message translates to:
  /// **'Save Mood Only'**
  String get saveMoodOnly;

  /// No description provided for @journalTodaysEntries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Entries'**
  String get journalTodaysEntries;

  /// No description provided for @journalHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get journalHistory;

  /// No description provided for @journalDailyReflection.
  ///
  /// In en, this message translates to:
  /// **'DAILY REFLECTION'**
  String get journalDailyReflection;

  /// No description provided for @journalReflectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal Reflection'**
  String get journalReflectionTitle;

  /// No description provided for @journalWritingTheme.
  ///
  /// In en, this message translates to:
  /// **'Writing Theme'**
  String get journalWritingTheme;

  /// No description provided for @journalTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Journal Title (Optional)'**
  String get journalTitleFieldLabel;

  /// No description provided for @journalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title your journal...'**
  String get journalTitleHint;

  /// No description provided for @journalWriteHint.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts here...'**
  String get journalWriteHint;

  /// No description provided for @journalFeelingLabel.
  ///
  /// In en, this message translates to:
  /// **'Feeling:'**
  String get journalFeelingLabel;

  /// No description provided for @insightsMoodPattern.
  ///
  /// In en, this message translates to:
  /// **'Mood Pattern'**
  String get insightsMoodPattern;

  /// No description provided for @insightsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get insightsLast7Days;

  /// No description provided for @insightsKeyTakeaway.
  ///
  /// In en, this message translates to:
  /// **'KEY TAKEAWAY'**
  String get insightsKeyTakeaway;

  /// No description provided for @insightsMostFrequent.
  ///
  /// In en, this message translates to:
  /// **'MOST FREQUENT'**
  String get insightsMostFrequent;

  /// No description provided for @insightsWhatAffectsYourMood.
  ///
  /// In en, this message translates to:
  /// **'What affects your mood'**
  String get insightsWhatAffectsYourMood;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacySecurity;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsAboutLumina.
  ///
  /// In en, this message translates to:
  /// **'About Lumina'**
  String get settingsAboutLumina;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
