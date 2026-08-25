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

  /// No description provided for @activityHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get activityHealth;

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

  /// No description provided for @settingsNotificationsBlockedByOs.
  ///
  /// In en, this message translates to:
  /// **'Blocked in your phone\'s system settings — enable notifications for Moodlet there first.'**
  String get settingsNotificationsBlockedByOs;

  /// No description provided for @settingsOpenSystemNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Notification Settings'**
  String get settingsOpenSystemNotificationSettings;

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
  /// **'About Moodlet'**
  String get settingsAboutLumina;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get actionStartOver;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set, Friend!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your new digital hug — a private space that\'s yours alone. Whenever you\'re ready, let\'s take a moment for yourself.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start My First Check-in'**
  String get welcomeStartButton;

  /// No description provided for @appLockIncorrectPattern.
  ///
  /// In en, this message translates to:
  /// **'Incorrect pattern — try again'**
  String get appLockIncorrectPattern;

  /// No description provided for @appLockDrawToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Draw your pattern to unlock'**
  String get appLockDrawToUnlock;

  /// No description provided for @patternLockSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Pattern Lock'**
  String get patternLockSetupTitle;

  /// No description provided for @patternLockDrawNew.
  ///
  /// In en, this message translates to:
  /// **'Draw a new pattern'**
  String get patternLockDrawNew;

  /// No description provided for @patternLockConnectDots.
  ///
  /// In en, this message translates to:
  /// **'Connect at least 2 dots — try again'**
  String get patternLockConnectDots;

  /// No description provided for @patternLockDrawAgainConfirm.
  ///
  /// In en, this message translates to:
  /// **'Draw the pattern again to confirm'**
  String get patternLockDrawAgainConfirm;

  /// No description provided for @patternLockDidntMatch.
  ///
  /// In en, this message translates to:
  /// **'Patterns didn\'t match — draw a new pattern'**
  String get patternLockDidntMatch;

  /// No description provided for @patternLockSetSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Pattern Lock set'**
  String get patternLockSetSnackbar;

  /// No description provided for @helpSupportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help'**
  String get helpSupportHeroTitle;

  /// No description provided for @helpSupportHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A couple of quick answers below.'**
  String get helpSupportHeroSubtitle;

  /// No description provided for @helpSupportFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get helpSupportFaqTitle;

  /// No description provided for @helpSupportFaq1Q.
  ///
  /// In en, this message translates to:
  /// **'Is my data secured?'**
  String get helpSupportFaq1Q;

  /// No description provided for @helpSupportFaq1A.
  ///
  /// In en, this message translates to:
  /// **'Yes — your account and journal are protected by Firebase Authentication and Cloud Firestore, with access rules that restrict your data to your own signed-in account only. See the Privacy Policy (About Moodlet) for the full details.'**
  String get helpSupportFaq1A;

  /// No description provided for @helpSupportFaq2Q.
  ///
  /// In en, this message translates to:
  /// **'Can I use Moodlet on multiple devices?'**
  String get helpSupportFaq2Q;

  /// No description provided for @helpSupportFaq2A.
  ///
  /// In en, this message translates to:
  /// **'Yes — sign in with the same account on any device and your journal, mood history, and settings will all be right there. Pattern Lock is the only exception — it\'s set per-device, so you\'ll set it up again on a new one.'**
  String get helpSupportFaq2A;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String privacyPolicyLastUpdated(String date);

  /// No description provided for @privacyPolicyOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get privacyPolicyOverviewTitle;

  /// No description provided for @privacyPolicyOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Moodlet (\"we\", \"our\", \"the app\") is a personal journaling app. This policy explains what information the app collects, how it is used, and the choices you have. Using Moodlet means you agree to the practices described here.'**
  String get privacyPolicyOverviewBody;

  /// No description provided for @privacyPolicyInfoCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get privacyPolicyInfoCollectTitle;

  /// No description provided for @privacyPolicyInfoCollectBody.
  ///
  /// In en, this message translates to:
  /// **'• Account information: the email address and password you sign up with (your password is never visible to us — Firebase Authentication handles it directly).\n• Profile info you choose to add: a display name and/or profile photo.\n• Journal content: anything you write, the mood and tags/activities you record, and any photos or voice notes you attach to an entry.\n• Optional AI key: if you choose to connect a Google Gemini API key in Settings for AI-powered features, that key is stored so the app can use it — see \"Optional AI Features\" below.\n\nWe do not collect analytics, advertising identifiers, or location data, and Moodlet contains no ads or third-party trackers.'**
  String get privacyPolicyInfoCollectBody;

  /// No description provided for @privacyPolicyStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'How We Store Your Information'**
  String get privacyPolicyStorageTitle;

  /// No description provided for @privacyPolicyStorageBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and journal data are stored using Firebase Authentication and Cloud Firestore (Google Cloud infrastructure), encrypted in transit. Access rules restrict your data to your own signed-in account — no other user can read or write it. A copy is also cached on your device so the app works offline; that local copy is cleared when you delete your account.'**
  String get privacyPolicyStorageBody;

  /// No description provided for @privacyPolicyUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How We Use Your Information'**
  String get privacyPolicyUseTitle;

  /// No description provided for @privacyPolicyUseBody.
  ///
  /// In en, this message translates to:
  /// **'• To create and secure your account, and let you sign back in on any device.\n• To store and sync your journal entries so they\'re available whenever you open the app.\n• To show you your own mood trends and patterns within the app (Insights).\n• To send an optional local daily reminder notification, if you turn that on — this is scheduled entirely on your device and involves no data being sent anywhere.\n\nWe do not use your journal content for advertising, and we do not sell your information to anyone.'**
  String get privacyPolicyUseBody;

  /// No description provided for @privacyPolicyAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional AI Features'**
  String get privacyPolicyAiTitle;

  /// No description provided for @privacyPolicyAiBody.
  ///
  /// In en, this message translates to:
  /// **'Moodlet can use the Google Gemini API to suggest reflection prompts, refine your weekly mood trend, or generate a title from an entry — but only if you provide your own Gemini API key in Settings. If you do, the relevant entry text is sent directly to Google\'s Gemini API to generate that response, subject to Google\'s own privacy terms. If no key is set, none of this happens and no journal content ever leaves your device for this purpose.'**
  String get privacyPolicyAiBody;

  /// No description provided for @privacyPolicySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'On-Device Security Features'**
  String get privacyPolicySecurityTitle;

  /// No description provided for @privacyPolicySecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Pattern Lock (Settings → Privacy & Security) is stored only on your device and is never synced to our servers or visible to us — a drawn pattern is stored only as an irreversible hash, never in a form that could be read back.'**
  String get privacyPolicySecurityBody;

  /// No description provided for @privacyPolicyRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Retention & Deletion'**
  String get privacyPolicyRetentionTitle;

  /// No description provided for @privacyPolicyRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is kept for as long as your account exists. Deleting an entry from your timeline moves it to History for a limited time before it\'s permanently removed, so you can restore it if that was a mistake. You can permanently delete your entire account and all associated data at any time from Settings → Delete Account — this immediately and permanently removes your journal data, your local device cache, and your account itself.'**
  String get privacyPolicyRetentionBody;

  /// No description provided for @privacyPolicyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Children\'s Privacy'**
  String get privacyPolicyChildrenTitle;

  /// No description provided for @privacyPolicyChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Moodlet is not directed at children under 13, and we do not knowingly collect information from anyone under that age. If you believe a child has provided us with personal information, please contact us using the details below and we will delete it.'**
  String get privacyPolicyChildrenBody;

  /// No description provided for @privacyPolicyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes to This Policy'**
  String get privacyPolicyChangesTitle;

  /// No description provided for @privacyPolicyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'If this policy changes, the \"Last updated\" date at the top of this page will change too. Continuing to use Moodlet after an update means you accept the revised policy.'**
  String get privacyPolicyChangesBody;

  /// No description provided for @privacyPolicyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get privacyPolicyContactTitle;

  /// No description provided for @privacyPolicyContactBody.
  ///
  /// In en, this message translates to:
  /// **'Questions about this policy or your data? Reach us at {email}.'**
  String privacyPolicyContactBody(String email);

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get changePasswordSuccessSnackbar;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordCurrentValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get changePasswordCurrentValidator;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordNewHelper.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters.'**
  String get changePasswordNewHelper;

  /// No description provided for @changePasswordNewValidatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get changePasswordNewValidatorEmpty;

  /// No description provided for @changePasswordNewValidatorLength.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get changePasswordNewValidatorLength;

  /// No description provided for @changePasswordNewValidatorSame.
  ///
  /// In en, this message translates to:
  /// **'Choose a different password than your current one'**
  String get changePasswordNewValidatorSame;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordConfirmValidatorMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get changePasswordConfirmValidatorMismatch;

  /// No description provided for @privacySecurityIntro.
  ///
  /// In en, this message translates to:
  /// **'Keep your journal for your eyes only — protect your account and lock the app on this device.'**
  String get privacySecurityIntro;

  /// No description provided for @privacySecurityAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get privacySecurityAccountSecurity;

  /// No description provided for @privacySecurityPatternLockRow.
  ///
  /// In en, this message translates to:
  /// **'Pattern Lock'**
  String get privacySecurityPatternLockRow;

  /// No description provided for @privacySecurityOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get privacySecurityOn;

  /// No description provided for @privacySecurityNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get privacySecurityNotSet;

  /// No description provided for @privacySecurityChangePattern.
  ///
  /// In en, this message translates to:
  /// **'Change Pattern'**
  String get privacySecurityChangePattern;

  /// No description provided for @privacySecurityRemovePattern.
  ///
  /// In en, this message translates to:
  /// **'Remove Pattern'**
  String get privacySecurityRemovePattern;

  /// No description provided for @privacySecurityRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Pattern Lock?'**
  String get privacySecurityRemoveDialogTitle;

  /// No description provided for @privacySecurityRemoveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll no longer need a pattern to open Moodlet.'**
  String get privacySecurityRemoveDialogBody;

  /// No description provided for @privacySecurityPatternRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Pattern Lock removed'**
  String get privacySecurityPatternRemovedSnackbar;

  /// No description provided for @aboutHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Digital Sanctuary'**
  String get aboutHeroTitle;

  /// No description provided for @aboutHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Moodlet was created as a safe, non-judgmental space for emotional reflection. We believe taking a moment for yourself shouldn\'t feel like a chore, but a gentle habit of self-care. Here, you can pause, breathe, and untangle your thoughts in a calm space designed for mindful growth.'**
  String get aboutHeroBody;

  /// No description provided for @aboutCoreValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Core Values'**
  String get aboutCoreValuesTitle;

  /// No description provided for @aboutValuePrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get aboutValuePrivacyTitle;

  /// No description provided for @aboutValuePrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your reflections belong solely to you. Your journal is stored in your own private account, never shared or sold, and yours to delete completely whenever you\'d like.'**
  String get aboutValuePrivacyBody;

  /// No description provided for @aboutValueGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Mindful Growth'**
  String get aboutValueGrowthTitle;

  /// No description provided for @aboutValueGrowthBody.
  ///
  /// In en, this message translates to:
  /// **'We design interactions to foster gentle self-awareness, avoiding addictive loops in favor of intentional, meaningful check-ins.'**
  String get aboutValueGrowthBody;

  /// No description provided for @aboutValueCreativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Creative Expression'**
  String get aboutValueCreativeTitle;

  /// No description provided for @aboutValueCreativeBody.
  ///
  /// In en, this message translates to:
  /// **'An open canvas for your emotions — words, mood colors, photos, voice notes, and tags — so your feelings can take whatever shape suits them.'**
  String get aboutValueCreativeBody;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} Moodlet Journal. All rights reserved.'**
  String aboutCopyright(int year);

  /// No description provided for @entryFeelingMood.
  ///
  /// In en, this message translates to:
  /// **'Feeling {mood}'**
  String entryFeelingMood(String mood);

  /// No description provided for @insightsNoneYet.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get insightsNoneYet;

  /// No description provided for @todayPickMoodFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a mood first 🙂'**
  String get todayPickMoodFirst;

  /// No description provided for @todayEntryLimitSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {limit}-entry limit is reached — delete one to add another.'**
  String todayEntryLimitSnackbar(int limit);

  /// No description provided for @todayEntryLimitBanner.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {limit}-entry limit is reached.'**
  String todayEntryLimitBanner(int limit);

  /// No description provided for @todayMoodSaved.
  ///
  /// In en, this message translates to:
  /// **'Mood saved to your journal 📖'**
  String get todayMoodSaved;

  /// No description provided for @todayCustomActivityCap.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} custom activities'**
  String todayCustomActivityCap(int max);

  /// No description provided for @todayCustomActivityHint.
  ///
  /// In en, this message translates to:
  /// **'What else?'**
  String get todayCustomActivityHint;

  /// No description provided for @editEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntryTitle;

  /// No description provided for @editEntryTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get editEntryTagsLabel;

  /// No description provided for @editEntrySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editEntrySaveChanges;

  /// No description provided for @deletedEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted Entries'**
  String get deletedEntriesTitle;

  /// No description provided for @deletedEntriesClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get deletedEntriesClearAll;

  /// No description provided for @deletedEntriesSlotsUsed.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} deleted slots'**
  String deletedEntriesSlotsUsed(int count, int max);

  /// No description provided for @deletedEntriesExpiryNote.
  ///
  /// In en, this message translates to:
  /// **'Deleted entries are permanently removed after {days} days.'**
  String deletedEntriesExpiryNote(int days);

  /// No description provided for @deletedEntriesPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get deletedEntriesPrevPage;

  /// No description provided for @deletedEntriesNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get deletedEntriesNextPage;

  /// No description provided for @deletedEntriesConfirmClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all?'**
  String get deletedEntriesConfirmClearAllTitle;

  /// No description provided for @deletedEntriesConfirmClearAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete 1 deleted entry from {date}. This can\'t be undone.} other{This will permanently delete all {count} deleted entries from {date}. This can\'t be undone.}}'**
  String deletedEntriesConfirmClearAllBody(num count, String date);

  /// No description provided for @deletedEntriesDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deletedEntriesDeleteAll;

  /// No description provided for @deletedEntriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Deleted Entries'**
  String get deletedEntriesEmptyTitle;

  /// No description provided for @deletedEntriesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing deleted from {date}. Entries you delete show up here so you can restore them or remove them for good.'**
  String deletedEntriesEmptyBody(String date);

  /// No description provided for @deletedEntriesBadge.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedEntriesBadge;

  /// No description provided for @deletedEntriesRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get deletedEntriesRestore;

  /// No description provided for @deletedEntriesDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deletedEntriesDeleteForever;

  /// No description provided for @deletedEntriesCantRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t restore'**
  String get deletedEntriesCantRestoreTitle;

  /// No description provided for @deletedEntriesCantRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'{date} already has {max} entries — delete one from that day before restoring this.'**
  String deletedEntriesCantRestoreBody(String date, int max);

  /// No description provided for @deletedEntriesDeleteForeverConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete forever?'**
  String get deletedEntriesDeleteForeverConfirmTitle;

  /// No description provided for @deletedEntriesDeleteForeverConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently removed. This can\'t be undone.'**
  String deletedEntriesDeleteForeverConfirmBody(String title);

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Moodlet and start your journaling journey.'**
  String get authJoinSubtitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey of mindfulness.'**
  String get authSignInSubtitle;

  /// No description provided for @authAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get authAddPhoto;

  /// No description provided for @authChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get authChangePhoto;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailEmptyValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailEmptyValidator;

  /// No description provided for @authEmailInvalidValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalidValidator;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters.'**
  String get authPasswordHelper;

  /// No description provided for @authPasswordEmptyValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordEmptyValidator;

  /// No description provided for @authPasswordLengthValidator.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get authPasswordLengthValidator;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authDontHaveAccount;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authQuickTestSignIn.
  ///
  /// In en, this message translates to:
  /// **'Quick Test Sign In'**
  String get authQuickTestSignIn;

  /// No description provided for @authForgotPasswordNeedEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above first, then tap \"Forgot password?\" again.'**
  String get authForgotPasswordNeedEmail;

  /// No description provided for @authPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email} — check your spam/junk folder if it doesn\'t show up.'**
  String authPasswordResetSent(String email);

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @auraChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Aura AI'**
  String get auraChatTitle;

  /// No description provided for @auraClearChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get auraClearChatTooltip;

  /// No description provided for @auraClearChatDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear chat?'**
  String get auraClearChatDialogTitle;

  /// No description provided for @auraClearChatDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This conversation with Aura will be cleared. This can\'t be undone.'**
  String get auraClearChatDialogBody;

  /// No description provided for @auraClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get auraClearConfirm;

  /// No description provided for @auraTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get auraTypeMessageHint;

  /// No description provided for @auraNotAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Currently not available for chat'**
  String get auraNotAvailableHint;

  /// No description provided for @auraErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Aura — check your connection and try again.'**
  String get auraErrorNetwork;

  /// No description provided for @auraErrorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Aura isn\'t set up correctly — check your API key in Settings.'**
  String get auraErrorBadRequest;

  /// No description provided for @auraErrorDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Not available — today\'s usage limit has been reached. Try again tomorrow.'**
  String get auraErrorDailyLimit;

  /// No description provided for @auraErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Aura\'s a little busy right now — try again in a few minutes.'**
  String get auraErrorRateLimited;

  /// No description provided for @auraErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Not available right now. Try again in a moment.'**
  String get auraErrorServer;

  /// No description provided for @auraErrorBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read Aura\'s response. Try again in a moment.'**
  String get auraErrorBadResponse;

  /// No description provided for @auraQuickReply1.
  ///
  /// In en, this message translates to:
  /// **'I need to vent'**
  String get auraQuickReply1;

  /// No description provided for @auraQuickReply2.
  ///
  /// In en, this message translates to:
  /// **'Breathing exercise'**
  String get auraQuickReply2;

  /// No description provided for @auraQuickReply3.
  ///
  /// In en, this message translates to:
  /// **'Just chatting'**
  String get auraQuickReply3;

  /// No description provided for @auraQuickReply4.
  ///
  /// In en, this message translates to:
  /// **'Help me reflect on today'**
  String get auraQuickReply4;

  /// No description provided for @auraQuickReply5.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling anxious'**
  String get auraQuickReply5;

  /// No description provided for @auraQuickReply6.
  ///
  /// In en, this message translates to:
  /// **'Celebrate a win with me'**
  String get auraQuickReply6;

  /// No description provided for @auraQuickReply7.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling great today'**
  String get auraQuickReply7;

  /// No description provided for @auraQuickReply8.
  ///
  /// In en, this message translates to:
  /// **'Give me a journal prompt'**
  String get auraQuickReply8;

  /// No description provided for @auraQuickReply9.
  ///
  /// In en, this message translates to:
  /// **'I need some encouragement'**
  String get auraQuickReply9;

  /// No description provided for @auraQuickReply10.
  ///
  /// In en, this message translates to:
  /// **'Help me unwind'**
  String get auraQuickReply10;

  /// No description provided for @auraQuickReply11.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling stuck'**
  String get auraQuickReply11;

  /// No description provided for @auraQuickReply12.
  ///
  /// In en, this message translates to:
  /// **'Something to be grateful for'**
  String get auraQuickReply12;

  /// No description provided for @entriesHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String entriesHistoryCount(num count);

  /// No description provided for @voiceNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNoteLabel;

  /// No description provided for @topBarHideAura.
  ///
  /// In en, this message translates to:
  /// **'Hide Aura companion'**
  String get topBarHideAura;

  /// No description provided for @topBarShowAura.
  ///
  /// In en, this message translates to:
  /// **'Show Aura companion'**
  String get topBarShowAura;

  /// No description provided for @voiceRecorderMicPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission wasn\'t granted.'**
  String get voiceRecorderMicPermissionDenied;

  /// No description provided for @voiceRecorderStartError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start recording: {error}'**
  String voiceRecorderStartError(String error);

  /// No description provided for @voiceRecorderSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the recording: {error}'**
  String voiceRecorderSaveError(String error);

  /// No description provided for @voiceRecorderMaxDuration.
  ///
  /// In en, this message translates to:
  /// **'Max 60 seconds'**
  String get voiceRecorderMaxDuration;

  /// No description provided for @voiceRecorderStopSave.
  ///
  /// In en, this message translates to:
  /// **'Stop & Save'**
  String get voiceRecorderStopSave;

  /// No description provided for @auraHintBubble.
  ///
  /// In en, this message translates to:
  /// **'Need to talk? I\'m here for you.'**
  String get auraHintBubble;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your digital hug.'**
  String get settingsSubtitle;

  /// No description provided for @settingsEditPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit Photo'**
  String get settingsEditPhoto;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsAiCompanion.
  ///
  /// In en, this message translates to:
  /// **'AI Companion'**
  String get settingsAiCompanion;

  /// No description provided for @settingsEnableAura.
  ///
  /// In en, this message translates to:
  /// **'Enable Aura'**
  String get settingsEnableAura;

  /// No description provided for @settingsEnableAuraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let the floating Aura chatbot accompany you.'**
  String get settingsEnableAuraSubtitle;

  /// No description provided for @settingsTestingTools.
  ///
  /// In en, this message translates to:
  /// **'Testing Tools'**
  String get settingsTestingTools;

  /// No description provided for @settingsTestingToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Not a real feature — just here to make QA-ing today\'s UI states easier.'**
  String get settingsTestingToolsSubtitle;

  /// No description provided for @settingsClearTodayButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Today\'s Entries'**
  String get settingsClearTodayButton;

  /// No description provided for @settingsFillPastWeek.
  ///
  /// In en, this message translates to:
  /// **'Fill Past 7 Days'**
  String get settingsFillPastWeek;

  /// No description provided for @settingsFillPastWeekSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added a week\'s worth of test entries'**
  String get settingsFillPastWeekSnackbar;

  /// No description provided for @settingsClearAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All Entries'**
  String get settingsClearAllButton;

  /// No description provided for @settingsTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get settingsTestNotification;

  /// No description provided for @settingsTestNotificationSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent — check your notification shade'**
  String get settingsTestNotificationSnackbar;

  /// No description provided for @settingsTestNotificationDisabledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Turn on Notifications above first'**
  String get settingsTestNotificationDisabledSnackbar;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsEditNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get settingsEditNameDialogTitle;

  /// No description provided for @settingsNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsNameHint;

  /// No description provided for @settingsTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get settingsTakePhoto;

  /// No description provided for @settingsChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get settingsChooseFromGallery;

  /// No description provided for @settingsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get settingsRemovePhoto;

  /// No description provided for @settingsClearTodayConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear today\'s entries?'**
  String get settingsClearTodayConfirmTitle;

  /// No description provided for @settingsClearTodayConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Soft-deletes every entry logged today (they\'re recoverable from History, same as swipe-delete) — lets you re-test things like the Insights check-in card that only show when today has nothing logged yet.'**
  String get settingsClearTodayConfirmBody;

  /// No description provided for @settingsClearTodaySnackbar.
  ///
  /// In en, this message translates to:
  /// **'Today\'s entries cleared'**
  String get settingsClearTodaySnackbar;

  /// No description provided for @settingsClearAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear every entry?'**
  String get settingsClearAllConfirmTitle;

  /// No description provided for @settingsClearAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently wipes every entry — live and already in Deleted History alike — for a genuinely clean slate. Unlike \"Clear Today\'s Entries,\" this can\'t be undone.'**
  String get settingsClearAllConfirmBody;

  /// No description provided for @settingsClearAllConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Everything'**
  String get settingsClearAllConfirmButton;

  /// No description provided for @settingsClearAllSnackbar.
  ///
  /// In en, this message translates to:
  /// **'All entries cleared'**
  String get settingsClearAllSnackbar;

  /// No description provided for @settingsLogOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogOutConfirmTitle;

  /// No description provided for @settingsLogOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign back in to see your journal.'**
  String get settingsLogOutConfirmBody;

  /// No description provided for @entryShareCaption.
  ///
  /// In en, this message translates to:
  /// **'My mood insight — shared with Moodlet 🌙'**
  String get entryShareCaption;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moodlet'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Take a moment to reflect. 🌙'**
  String get notificationBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentle daily nudge to check in with yourself.'**
  String get notificationChannelDescription;

  /// No description provided for @actionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// No description provided for @actionYesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get actionYesDelete;

  /// No description provided for @deletedHistoryFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted history is full'**
  String get deletedHistoryFullTitle;

  /// No description provided for @deletedHistoryFullBody.
  ///
  /// In en, this message translates to:
  /// **'This day\'s History already has {max} deleted entries. Restore or permanently delete some from History before deleting another.'**
  String deletedHistoryFullBody(int max);

  /// No description provided for @entryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get entryDeleteConfirmTitle;

  /// No description provided for @entryDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from this day? You can restore it later from History.'**
  String entryDeleteConfirmBody(String title);

  /// No description provided for @entryDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get entryDeletedSnackbar;

  /// No description provided for @entryShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get entryShowLess;

  /// No description provided for @entryShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get entryShowMore;

  /// No description provided for @calendarNoEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries on this day yet.'**
  String get calendarNoEntriesYet;

  /// No description provided for @calendarWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get calendarWeekdaySun;

  /// No description provided for @calendarWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get calendarWeekdayMon;

  /// No description provided for @calendarWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get calendarWeekdayTue;

  /// No description provided for @calendarWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get calendarWeekdayWed;

  /// No description provided for @calendarWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get calendarWeekdayThu;

  /// No description provided for @calendarWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get calendarWeekdayFri;

  /// No description provided for @calendarWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get calendarWeekdaySat;

  /// No description provided for @journalNothingLoggedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet today.'**
  String get journalNothingLoggedYet;

  /// No description provided for @journalDailySlots.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} daily slots'**
  String journalDailySlots(int count, int max);

  /// No description provided for @journalPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos (Optional)'**
  String get journalPhotosLabel;

  /// No description provided for @journalPhotosLabelCount.
  ///
  /// In en, this message translates to:
  /// **'Photos (Optional) · {count}/{max}'**
  String journalPhotosLabelCount(int count, int max);

  /// No description provided for @journalAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get journalAddPhoto;

  /// No description provided for @journalAddMorePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get journalAddMorePhoto;

  /// No description provided for @journalVoiceNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get journalVoiceNoteButton;

  /// No description provided for @journalTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (Optional)'**
  String get journalTagsLabel;

  /// No description provided for @journalAddTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get journalAddTagHint;

  /// No description provided for @journalSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Journal'**
  String get journalSaveButton;

  /// No description provided for @journalEntrySavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Entry saved to your journal 📖'**
  String get journalEntrySavedSnackbar;

  /// No description provided for @journalPhotoCap.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} photos per entry'**
  String journalPhotoCap(int max);

  /// No description provided for @journalCustomTagCap.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} custom tags'**
  String journalCustomTagCap(int max);

  /// No description provided for @journalDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from your timeline? You can restore it later from History.'**
  String journalDeleteConfirmBody(String title);

  /// No description provided for @journalReflectionFallback1.
  ///
  /// In en, this message translates to:
  /// **'What\'s one small thing that made you smile today?'**
  String get journalReflectionFallback1;

  /// No description provided for @journalReflectionFallback2.
  ///
  /// In en, this message translates to:
  /// **'What\'s something you\'re looking forward to?'**
  String get journalReflectionFallback2;

  /// No description provided for @journalReflectionFallback3.
  ///
  /// In en, this message translates to:
  /// **'Is there a moment today you\'d like to remember?'**
  String get journalReflectionFallback3;

  /// No description provided for @journalReflectionFallback4.
  ///
  /// In en, this message translates to:
  /// **'What\'s weighing on your mind right now?'**
  String get journalReflectionFallback4;

  /// No description provided for @journalReflectionFallback5.
  ///
  /// In en, this message translates to:
  /// **'What\'s one thing you\'re grateful for today?'**
  String get journalReflectionFallback5;

  /// No description provided for @journalReflectionFallback6.
  ///
  /// In en, this message translates to:
  /// **'How did you take care of yourself today?'**
  String get journalReflectionFallback6;

  /// No description provided for @journalReflectionFallback7.
  ///
  /// In en, this message translates to:
  /// **'What would make tomorrow a little better?'**
  String get journalReflectionFallback7;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @entryToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get entryToday;

  /// No description provided for @entryShareTagsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Tags: '**
  String get entryShareTagsPrefix;

  /// No description provided for @entrySavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Entry saved'**
  String get entrySavedSnackbar;

  /// No description provided for @entryRestoredSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Entry restored'**
  String get entryRestoredSnackbar;

  /// No description provided for @entryNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'This entry no longer exists.'**
  String get entryNoLongerExists;

  /// No description provided for @entryAddVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Add Voice Note'**
  String get entryAddVoiceNote;

  /// No description provided for @entryTagCap.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} tags per entry'**
  String entryTagCap(int max);

  /// No description provided for @entryNoReflectionYet.
  ///
  /// In en, this message translates to:
  /// **'No reflection yet — start writing when you\'re ready.'**
  String get entryNoReflectionYet;

  /// No description provided for @entryMomentsCaptured.
  ///
  /// In en, this message translates to:
  /// **'Moments Captured'**
  String get entryMomentsCaptured;

  /// No description provided for @entryMomentsCapturedCount.
  ///
  /// In en, this message translates to:
  /// **'Moments Captured · {count}/{max}'**
  String entryMomentsCapturedCount(int count, int max);

  /// No description provided for @entryEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get entryEditTooltip;

  /// No description provided for @entryNewTagHint.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get entryNewTagHint;

  /// No description provided for @insightsMoodJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Mood Journey'**
  String get insightsMoodJourneyTitle;

  /// No description provided for @insightsMoodJourneySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how you\'ve been feeling this week. Remember, every feeling is valid.'**
  String get insightsMoodJourneySubtitle;

  /// No description provided for @insightsRecordedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Recorded 1 time recently} other{Recorded {count} times recently}}'**
  String insightsRecordedTimes(num count);

  /// No description provided for @insightsWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get insightsWelcomeBack;

  /// No description provided for @insightsReminderOn.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder turned on'**
  String get insightsReminderOn;

  /// No description provided for @insightsReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder turned off'**
  String get insightsReminderOff;

  /// No description provided for @insightsReminderOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn on daily reminder'**
  String get insightsReminderOnTooltip;

  /// No description provided for @insightsReminderOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn off daily reminder'**
  String get insightsReminderOffTooltip;

  /// No description provided for @insightsFeelingRightNow.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get insightsFeelingRightNow;

  /// No description provided for @insightsCheckInNow.
  ///
  /// In en, this message translates to:
  /// **'Check in now'**
  String get insightsCheckInNow;

  /// No description provided for @insightsTrackMoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your mood to see patterns and get insights.'**
  String get insightsTrackMoodSubtitle;

  /// No description provided for @insightsGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get insightsGreetingMorning;

  /// No description provided for @insightsGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get insightsGreetingAfternoon;

  /// No description provided for @insightsGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get insightsGreetingEvening;

  /// No description provided for @insightsGreetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get insightsGreetingNight;

  /// No description provided for @insightsLogMoreEntries.
  ///
  /// In en, this message translates to:
  /// **'Log a few more entries with activities to see patterns.'**
  String get insightsLogMoreEntries;

  /// No description provided for @insightsCorrelationSentence.
  ///
  /// In en, this message translates to:
  /// **'You feel {mood} when you\n{activity}'**
  String insightsCorrelationSentence(String mood, String activity);

  /// No description provided for @insightsNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get insightsNoDataYet;

  /// No description provided for @insightsLogMoodToStart.
  ///
  /// In en, this message translates to:
  /// **'Log a mood to start seeing your trend.'**
  String get insightsLogMoodToStart;

  /// No description provided for @insightsSummaryNeedMore.
  ///
  /// In en, this message translates to:
  /// **'Log a few more moods this week to start seeing a trend.'**
  String get insightsSummaryNeedMore;

  /// No description provided for @insightsSummaryTrendingUp.
  ///
  /// In en, this message translates to:
  /// **'Trending upward this week — nice momentum, keep it going.'**
  String get insightsSummaryTrendingUp;

  /// No description provided for @insightsSummaryTougher.
  ///
  /// In en, this message translates to:
  /// **'A tougher stretch this week — be gentle with yourself.'**
  String get insightsSummaryTougher;

  /// No description provided for @insightsSummaryGreatWeek.
  ///
  /// In en, this message translates to:
  /// **'A genuinely great week overall — whatever you\'re doing, keep it up.'**
  String get insightsSummaryGreatWeek;

  /// No description provided for @insightsSummaryHeavierWeek.
  ///
  /// In en, this message translates to:
  /// **'A heavier week than usual — might be worth some extra care.'**
  String get insightsSummaryHeavierWeek;

  /// No description provided for @insightsSummarySteady.
  ///
  /// In en, this message translates to:
  /// **'Pretty steady this week — nothing dramatic either way.'**
  String get insightsSummarySteady;

  /// No description provided for @weeklyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Detail'**
  String get weeklyDetailTitle;

  /// No description provided for @weeklyMoodOverview.
  ///
  /// In en, this message translates to:
  /// **'Mood Overview'**
  String get weeklyMoodOverview;

  /// No description provided for @weeklyDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY DISTRIBUTION'**
  String get weeklyDistributionTitle;

  /// No description provided for @weeklyLogMoodBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Log a mood this week to see a breakdown.'**
  String get weeklyLogMoodBreakdown;

  /// No description provided for @weeklyMoodCount.
  ///
  /// In en, this message translates to:
  /// **'{mood} ({count})'**
  String weeklyMoodCount(String mood, int count);

  /// No description provided for @weeklyMoodPercentageTitle.
  ///
  /// In en, this message translates to:
  /// **'MOOD PERCENTAGE'**
  String get weeklyMoodPercentageTitle;

  /// No description provided for @weeklyPositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get weeklyPositive;

  /// No description provided for @weeklyNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get weeklyNeutral;

  /// No description provided for @weeklyNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get weeklyNegative;

  /// No description provided for @weeklyKeyInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Insight'**
  String get weeklyKeyInsightTitle;

  /// No description provided for @weeklyFallbackNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Log a few entries this week to start seeing patterns.'**
  String get weeklyFallbackNoEntries;

  /// No description provided for @weeklyFallbackSteady.
  ///
  /// In en, this message translates to:
  /// **'Pretty steady week — log a few more tagged entries and I\'ll start spotting real patterns.'**
  String get weeklyFallbackSteady;

  /// No description provided for @weeklyInsightPhrase.
  ///
  /// In en, this message translates to:
  /// **'{percent}% {direction, select, better{better} other{worse}} on days you log \"{label}\"'**
  String weeklyInsightPhrase(int percent, String direction, String label);

  /// No description provided for @weeklyInsightTailPositive.
  ///
  /// In en, this message translates to:
  /// **'worth leaning into.'**
  String get weeklyInsightTailPositive;

  /// No description provided for @weeklyInsightTailNegative.
  ///
  /// In en, this message translates to:
  /// **'might be worth noticing.'**
  String get weeklyInsightTailNegative;

  /// No description provided for @weeklyInsightSingle.
  ///
  /// In en, this message translates to:
  /// **'You feel {phrase} — {tail}'**
  String weeklyInsightSingle(String phrase, String tail);

  /// No description provided for @weeklyInsightBoth.
  ///
  /// In en, this message translates to:
  /// **'You feel {best}, but {worst}.'**
  String weeklyInsightBoth(String best, String worst);

  /// No description provided for @weeklyShareIntro.
  ///
  /// In en, this message translates to:
  /// **'My weekly mood detail from Moodlet 🧘'**
  String get weeklyShareIntro;

  /// No description provided for @weeklyShareMoodCount.
  ///
  /// In en, this message translates to:
  /// **'{mood}: {count}'**
  String weeklyShareMoodCount(String mood, int count);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountHeading.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountHeading;

  /// No description provided for @deleteAccountBodyIntro.
  ///
  /// In en, this message translates to:
  /// **'We\'re sad to see you go. If you delete your account, your digital sanctuary will be permanently removed. '**
  String get deleteAccountBodyIntro;

  /// No description provided for @deleteAccountBodyBold.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteAccountBodyBold;

  /// No description provided for @deleteAccountWhatYoullLose.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll lose'**
  String get deleteAccountWhatYoullLose;

  /// No description provided for @deleteAccountJournalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Journals'**
  String get deleteAccountJournalsTitle;

  /// No description provided for @deleteAccountJournalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All written entries and reflections'**
  String get deleteAccountJournalsSubtitle;

  /// No description provided for @deleteAccountMoodHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood History'**
  String get deleteAccountMoodHistoryTitle;

  /// No description provided for @deleteAccountMoodHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your tracked emotional journey'**
  String get deleteAccountMoodHistorySubtitle;

  /// No description provided for @deleteAccountConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password to continue'**
  String get deleteAccountConfirmPassword;

  /// No description provided for @deleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get deleteAccountPasswordHint;

  /// No description provided for @deleteAccountKeepButton.
  ///
  /// In en, this message translates to:
  /// **'Keep My Account'**
  String get deleteAccountKeepButton;

  /// No description provided for @deleteAccountDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountDeleteButton;

  /// No description provided for @tourInsightsTab.
  ///
  /// In en, this message translates to:
  /// **'See your mood trends and patterns here.'**
  String get tourInsightsTab;

  /// No description provided for @tourTodayTab.
  ///
  /// In en, this message translates to:
  /// **'Log how you\'re feeling, right now.'**
  String get tourTodayTab;

  /// No description provided for @tourJournalTab.
  ///
  /// In en, this message translates to:
  /// **'Read and write your journal entries.'**
  String get tourJournalTab;

  /// No description provided for @tourCalendarTab.
  ///
  /// In en, this message translates to:
  /// **'Browse any past day by date.'**
  String get tourCalendarTab;

  /// No description provided for @tourAuraFab.
  ///
  /// In en, this message translates to:
  /// **'Meet Aura — tap anytime for a supportive chat.'**
  String get tourAuraFab;

  /// No description provided for @tourSettingsIcon.
  ///
  /// In en, this message translates to:
  /// **'Preferences, privacy, and more live here.'**
  String get tourSettingsIcon;

  /// No description provided for @settingsTakeTour.
  ///
  /// In en, this message translates to:
  /// **'Take a Tour'**
  String get settingsTakeTour;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tourDone;

  /// No description provided for @loadingPreparingJournal.
  ///
  /// In en, this message translates to:
  /// **'Preparing your journal...'**
  String get loadingPreparingJournal;

  /// No description provided for @auraGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi there! I\'m Aura, your mindful companion. How are you feeling today?'**
  String get auraGreeting;

  /// No description provided for @tourAuraToggle.
  ///
  /// In en, this message translates to:
  /// **'Turn Aura on here for a supportive chat companion.'**
  String get tourAuraToggle;
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
