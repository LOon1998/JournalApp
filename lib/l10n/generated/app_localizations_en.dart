// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navInsights => 'Insights';

  @override
  String get navToday => 'Today';

  @override
  String get navJournal => 'Journal';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get moodGreat => 'Great';

  @override
  String get moodGood => 'Good';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodAwful => 'Awful';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDone => 'Done';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionClose => 'Close';

  @override
  String get todayHeadline => 'How are you feeling today?';

  @override
  String get todayActivitiesTitle => 'What have you been up to?';

  @override
  String get activityWork => 'Work';

  @override
  String get activityFamily => 'Family';

  @override
  String get activityFriends => 'Friends';

  @override
  String get activityHobby => 'Hobby';

  @override
  String get activityExercise => 'Exercise';

  @override
  String get activitySleep => 'Sleep';

  @override
  String get activityOther => 'Other';

  @override
  String get activityHealth => 'Health';

  @override
  String get continueWriteJournal => 'Continue & Write\nJournal';

  @override
  String get saveMoodOnly => 'Save Mood Only';

  @override
  String get journalTodaysEntries => 'Today\'s Entries';

  @override
  String get journalHistory => 'History';

  @override
  String get journalDailyReflection => 'DAILY REFLECTION';

  @override
  String get journalReflectionTitle => 'Journal Reflection';

  @override
  String get journalWritingTheme => 'Writing Theme';

  @override
  String get journalTitleFieldLabel => 'Journal Title (Optional)';

  @override
  String get journalTitleHint => 'Title your journal...';

  @override
  String get journalWriteHint => 'Write your thoughts here...';

  @override
  String get journalFeelingLabel => 'Feeling:';

  @override
  String get insightsMoodPattern => 'Mood Pattern';

  @override
  String get insightsLast7Days => 'Last 7 Days';

  @override
  String get insightsKeyTakeaway => 'KEY TAKEAWAY';

  @override
  String get insightsMostFrequent => 'MOST FREQUENT';

  @override
  String get insightsWhatAffectsYourMood => 'What affects your mood';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsBlockedByOs =>
      'Blocked in your phone\'s system settings — enable notifications for Moodlet there first.';

  @override
  String get settingsOpenSystemNotificationSettings =>
      'Open Notification Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsPrivacySecurity => 'Privacy & Security';

  @override
  String get settingsHelpSupport => 'Help & Support';

  @override
  String get settingsAboutLumina => 'About Moodlet';

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionStartOver => 'Start Over';

  @override
  String get actionOk => 'OK';

  @override
  String get welcomeTitle => 'You\'re all set, Friend!';

  @override
  String get welcomeSubtitle =>
      'Welcome to your new digital hug — a private space that\'s yours alone. Whenever you\'re ready, let\'s take a moment for yourself.';

  @override
  String get welcomeStartButton => 'Start My First Check-in';

  @override
  String get appLockIncorrectPattern => 'Incorrect pattern — try again';

  @override
  String get appLockDrawToUnlock => 'Draw your pattern to unlock';

  @override
  String get patternLockSetupTitle => 'Set Pattern Lock';

  @override
  String get patternLockDrawNew => 'Draw a new pattern';

  @override
  String get patternLockConnectDots => 'Connect at least 2 dots — try again';

  @override
  String get patternLockDrawAgainConfirm => 'Draw the pattern again to confirm';

  @override
  String get patternLockDidntMatch =>
      'Patterns didn\'t match — draw a new pattern';

  @override
  String get patternLockSetSnackbar => 'Pattern Lock set';

  @override
  String get helpSupportHeroTitle => 'We\'re here to help';

  @override
  String get helpSupportHeroSubtitle => 'A couple of quick answers below.';

  @override
  String get helpSupportFaqTitle => 'Frequently Asked Questions';

  @override
  String get helpSupportFaq1Q => 'Is my data secured?';

  @override
  String get helpSupportFaq1A =>
      'Yes — your account and journal are protected by Firebase Authentication and Cloud Firestore, with access rules that restrict your data to your own signed-in account only. See the Privacy Policy (About Moodlet) for the full details.';

  @override
  String get helpSupportFaq2Q => 'Can I use Moodlet on multiple devices?';

  @override
  String get helpSupportFaq2A =>
      'Yes — sign in with the same account on any device and your journal, mood history, and settings will all be right there. Pattern Lock is the only exception — it\'s set per-device, so you\'ll set it up again on a new one.';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyPolicyOverviewTitle => 'Overview';

  @override
  String get privacyPolicyOverviewBody =>
      'Moodlet (\"we\", \"our\", \"the app\") is a personal journaling app. This policy explains what information the app collects, how it is used, and the choices you have. Using Moodlet means you agree to the practices described here.';

  @override
  String get privacyPolicyInfoCollectTitle => 'Information We Collect';

  @override
  String get privacyPolicyInfoCollectBody =>
      '• Account information: the email address and password you sign up with (your password is never visible to us — Firebase Authentication handles it directly).\n• Profile info you choose to add: a display name and/or profile photo.\n• Journal content: anything you write, the mood and tags/activities you record, and any photos or voice notes you attach to an entry.\n• Optional AI key: if you choose to connect a Google Gemini API key in Settings for AI-powered features, that key is stored so the app can use it — see \"Optional AI Features\" below.\n\nWe do not collect analytics, advertising identifiers, or location data, and Moodlet contains no ads or third-party trackers.';

  @override
  String get privacyPolicyStorageTitle => 'How We Store Your Information';

  @override
  String get privacyPolicyStorageBody =>
      'Your account and journal data are stored using Firebase Authentication and Cloud Firestore (Google Cloud infrastructure), encrypted in transit. Access rules restrict your data to your own signed-in account — no other user can read or write it. A copy is also cached on your device so the app works offline; that local copy is cleared when you delete your account.';

  @override
  String get privacyPolicyUseTitle => 'How We Use Your Information';

  @override
  String get privacyPolicyUseBody =>
      '• To create and secure your account, and let you sign back in on any device.\n• To store and sync your journal entries so they\'re available whenever you open the app.\n• To show you your own mood trends and patterns within the app (Insights).\n• To send an optional local daily reminder notification, if you turn that on — this is scheduled entirely on your device and involves no data being sent anywhere.\n\nWe do not use your journal content for advertising, and we do not sell your information to anyone.';

  @override
  String get privacyPolicyAiTitle => 'Optional AI Features';

  @override
  String get privacyPolicyAiBody =>
      'Moodlet can use the Google Gemini API to suggest reflection prompts, refine your weekly mood trend, or generate a title from an entry — but only if you provide your own Gemini API key in Settings. If you do, the relevant entry text is sent directly to Google\'s Gemini API to generate that response, subject to Google\'s own privacy terms. If no key is set, none of this happens and no journal content ever leaves your device for this purpose.';

  @override
  String get privacyPolicySecurityTitle => 'On-Device Security Features';

  @override
  String get privacyPolicySecurityBody =>
      'Pattern Lock (Settings → Privacy & Security) is stored only on your device and is never synced to our servers or visible to us — a drawn pattern is stored only as an irreversible hash, never in a form that could be read back.';

  @override
  String get privacyPolicyRetentionTitle => 'Data Retention & Deletion';

  @override
  String get privacyPolicyRetentionBody =>
      'Your data is kept for as long as your account exists. Deleting an entry from your timeline moves it to History for a limited time before it\'s permanently removed, so you can restore it if that was a mistake. You can permanently delete your entire account and all associated data at any time from Settings → Delete Account — this immediately and permanently removes your journal data, your local device cache, and your account itself.';

  @override
  String get privacyPolicyChildrenTitle => 'Children\'s Privacy';

  @override
  String get privacyPolicyChildrenBody =>
      'Moodlet is not directed at children under 13, and we do not knowingly collect information from anyone under that age. If you believe a child has provided us with personal information, please contact us using the details below and we will delete it.';

  @override
  String get privacyPolicyChangesTitle => 'Changes to This Policy';

  @override
  String get privacyPolicyChangesBody =>
      'If this policy changes, the \"Last updated\" date at the top of this page will change too. Continuing to use Moodlet after an update means you accept the revised policy.';

  @override
  String get privacyPolicyContactTitle => 'Contact Us';

  @override
  String privacyPolicyContactBody(String email) {
    return 'Questions about this policy or your data? Reach us at $email.';
  }

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSuccessSnackbar => 'Password changed';

  @override
  String get changePasswordCurrentLabel => 'Current Password';

  @override
  String get changePasswordCurrentValidator => 'Enter your current password';

  @override
  String get changePasswordNewLabel => 'New Password';

  @override
  String get changePasswordNewHelper => 'Must be at least 6 characters.';

  @override
  String get changePasswordNewValidatorEmpty => 'Enter a new password';

  @override
  String get changePasswordNewValidatorLength => 'At least 6 characters';

  @override
  String get changePasswordNewValidatorSame =>
      'Choose a different password than your current one';

  @override
  String get changePasswordConfirmLabel => 'Confirm New Password';

  @override
  String get changePasswordConfirmValidatorMismatch => 'Passwords don\'t match';

  @override
  String get privacySecurityIntro =>
      'Keep your journal for your eyes only — protect your account and lock the app on this device.';

  @override
  String get privacySecurityAccountSecurity => 'Account Security';

  @override
  String get privacySecurityPatternLockRow => 'Pattern Lock';

  @override
  String get privacySecurityOn => 'On';

  @override
  String get privacySecurityNotSet => 'Not set';

  @override
  String get privacySecurityChangePattern => 'Change Pattern';

  @override
  String get privacySecurityRemovePattern => 'Remove Pattern';

  @override
  String get privacySecurityRemoveDialogTitle => 'Remove Pattern Lock?';

  @override
  String get privacySecurityRemoveDialogBody =>
      'You\'ll no longer need a pattern to open Moodlet.';

  @override
  String get privacySecurityPatternRemovedSnackbar => 'Pattern Lock removed';

  @override
  String get aboutHeroTitle => 'Your Digital Sanctuary';

  @override
  String get aboutHeroBody =>
      'Moodlet was created as a safe, non-judgmental space for emotional reflection. We believe taking a moment for yourself shouldn\'t feel like a chore, but a gentle habit of self-care. Here, you can pause, breathe, and untangle your thoughts in a calm space designed for mindful growth.';

  @override
  String get aboutCoreValuesTitle => 'Our Core Values';

  @override
  String get aboutValuePrivacyTitle => 'Privacy First';

  @override
  String get aboutValuePrivacyBody =>
      'Your reflections belong solely to you. Your journal is stored in your own private account, never shared or sold, and yours to delete completely whenever you\'d like.';

  @override
  String get aboutValueGrowthTitle => 'Mindful Growth';

  @override
  String get aboutValueGrowthBody =>
      'We design interactions to foster gentle self-awareness, avoiding addictive loops in favor of intentional, meaningful check-ins.';

  @override
  String get aboutValueCreativeTitle => 'Creative Expression';

  @override
  String get aboutValueCreativeBody =>
      'An open canvas for your emotions — words, mood colors, photos, voice notes, and tags — so your feelings can take whatever shape suits them.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String aboutCopyright(int year) {
    return '© $year Moodlet Journal. All rights reserved.';
  }

  @override
  String entryFeelingMood(String mood) {
    return 'Feeling $mood';
  }

  @override
  String get insightsNoneYet => 'None yet';

  @override
  String get todayPickMoodFirst => 'Pick a mood first 🙂';

  @override
  String todayEntryLimitSnackbar(int limit) {
    return 'Today\'s $limit-entry limit is reached — delete one to add another.';
  }

  @override
  String todayEntryLimitBanner(int limit) {
    return 'Today\'s $limit-entry limit is reached.';
  }

  @override
  String get todayMoodSaved => 'Mood saved to your journal 📖';

  @override
  String todayCustomActivityCap(int max) {
    return 'Up to $max custom activities';
  }

  @override
  String get todayCustomActivityHint => 'What else?';

  @override
  String get editEntryTitle => 'Edit Entry';

  @override
  String get editEntryTagsLabel => 'Tags';

  @override
  String get editEntrySaveChanges => 'Save Changes';

  @override
  String get deletedEntriesTitle => 'Deleted Entries';

  @override
  String get deletedEntriesClearAll => 'Clear All';

  @override
  String deletedEntriesSlotsUsed(int count, int max) {
    return '$count of $max deleted slots';
  }

  @override
  String deletedEntriesExpiryNote(int days) {
    return 'Deleted entries are permanently removed after $days days.';
  }

  @override
  String get deletedEntriesPrevPage => 'Previous page';

  @override
  String get deletedEntriesNextPage => 'Next page';

  @override
  String get deletedEntriesConfirmClearAllTitle => 'Permanently delete all?';

  @override
  String deletedEntriesConfirmClearAllBody(num count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will permanently delete all $count deleted entries from $date. This can\'t be undone.',
      one:
          'This will permanently delete 1 deleted entry from $date. This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String get deletedEntriesDeleteAll => 'Delete All';

  @override
  String get deletedEntriesEmptyTitle => 'No Deleted Entries';

  @override
  String deletedEntriesEmptyBody(String date) {
    return 'Nothing deleted from $date. Entries you delete show up here so you can restore them or remove them for good.';
  }

  @override
  String get deletedEntriesBadge => 'Deleted';

  @override
  String get deletedEntriesRestore => 'Restore';

  @override
  String get deletedEntriesDeleteForever => 'Delete Forever';

  @override
  String get deletedEntriesCantRestoreTitle => 'Can\'t restore';

  @override
  String deletedEntriesCantRestoreBody(String date, int max) {
    return '$date already has $max entries — delete one from that day before restoring this.';
  }

  @override
  String get deletedEntriesDeleteForeverConfirmTitle => 'Delete forever?';

  @override
  String deletedEntriesDeleteForeverConfirmBody(String title) {
    return '\"$title\" will be permanently removed. This can\'t be undone.';
  }

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authJoinSubtitle =>
      'Join Moodlet and start your journaling journey.';

  @override
  String get authSignInSubtitle =>
      'Sign in to continue your journey of mindfulness.';

  @override
  String get authAddPhoto => 'Add Photo';

  @override
  String get authChangePhoto => 'Change Photo';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailEmptyValidator => 'Enter your email';

  @override
  String get authEmailInvalidValidator => 'Enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHelper => 'Must be at least 6 characters.';

  @override
  String get authPasswordEmptyValidator => 'Enter your password';

  @override
  String get authPasswordLengthValidator => 'At least 6 characters';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authDontHaveAccount => 'Don\'t have an account?';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authQuickTestSignIn => 'Quick Test Sign In';

  @override
  String get authForgotPasswordNeedEmail =>
      'Enter your email above first, then tap \"Forgot password?\" again.';

  @override
  String authPasswordResetSent(String email) {
    return 'Password reset email sent to $email — check your spam/junk folder if it doesn\'t show up.';
  }

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get auraChatTitle => 'Aura AI';

  @override
  String get auraClearChatTooltip => 'Clear chat';

  @override
  String get auraClearChatDialogTitle => 'Clear chat?';

  @override
  String get auraClearChatDialogBody =>
      'This conversation with Aura will be cleared. This can\'t be undone.';

  @override
  String get auraClearConfirm => 'Clear';

  @override
  String get auraTypeMessageHint => 'Type a message...';

  @override
  String get auraNotAvailableHint => 'Currently not available for chat';

  @override
  String get auraErrorNetwork =>
      'Could not reach Aura — check your connection and try again.';

  @override
  String get auraErrorBadRequest =>
      'Aura isn\'t set up correctly — check your API key in Settings.';

  @override
  String get auraErrorDailyLimit =>
      'Not available — today\'s usage limit has been reached. Try again tomorrow.';

  @override
  String get auraErrorRateLimited =>
      'Aura\'s a little busy right now — try again in a few minutes.';

  @override
  String get auraErrorServer =>
      'Not available right now. Try again in a moment.';

  @override
  String get auraErrorBadResponse =>
      'Couldn\'t read Aura\'s response. Try again in a moment.';

  @override
  String get auraQuickReply1 => 'I need to vent';

  @override
  String get auraQuickReply2 => 'Breathing exercise';

  @override
  String get auraQuickReply3 => 'Just chatting';

  @override
  String get auraQuickReply4 => 'Help me reflect on today';

  @override
  String get auraQuickReply5 => 'I\'m feeling anxious';

  @override
  String get auraQuickReply6 => 'Celebrate a win with me';

  @override
  String get auraQuickReply7 => 'I\'m feeling great today';

  @override
  String get auraQuickReply8 => 'Give me a journal prompt';

  @override
  String get auraQuickReply9 => 'I need some encouragement';

  @override
  String get auraQuickReply10 => 'Help me unwind';

  @override
  String get auraQuickReply11 => 'I\'m feeling stuck';

  @override
  String get auraQuickReply12 => 'Something to be grateful for';

  @override
  String entriesHistoryCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get voiceNoteLabel => 'Voice note';

  @override
  String get topBarHideAura => 'Hide Aura companion';

  @override
  String get topBarShowAura => 'Show Aura companion';

  @override
  String get voiceRecorderMicPermissionDenied =>
      'Microphone permission wasn\'t granted.';

  @override
  String voiceRecorderStartError(String error) {
    return 'Couldn\'t start recording: $error';
  }

  @override
  String voiceRecorderSaveError(String error) {
    return 'Couldn\'t save the recording: $error';
  }

  @override
  String get voiceRecorderMaxDuration => 'Max 60 seconds';

  @override
  String get voiceRecorderStopSave => 'Stop & Save';

  @override
  String get auraHintBubble => 'Need to talk? I\'m here for you.';

  @override
  String get actionClear => 'Clear';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsSubtitle => 'Customize your digital hug.';

  @override
  String get settingsEditPhoto => 'Edit Photo';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsAiCompanion => 'AI Companion';

  @override
  String get settingsEnableAura => 'Enable Aura';

  @override
  String get settingsEnableAuraSubtitle =>
      'Let the floating Aura chatbot accompany you.';

  @override
  String get settingsTestingTools => 'Testing Tools';

  @override
  String get settingsTestingToolsSubtitle =>
      'Not a real feature — just here to make QA-ing today\'s UI states easier.';

  @override
  String get settingsClearTodayButton => 'Clear Today\'s Entries';

  @override
  String get settingsFillPastWeek => 'Fill Past 7 Days';

  @override
  String get settingsFillPastWeekSnackbar =>
      'Added a week\'s worth of test entries';

  @override
  String get settingsClearAllButton => 'Clear All Entries';

  @override
  String get settingsTestNotification => 'Test Notification';

  @override
  String get settingsTestNotificationSnackbar =>
      'Test notification sent — check your notification shade';

  @override
  String get settingsTestNotificationDisabledSnackbar =>
      'Turn on Notifications above first';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsEditNameDialogTitle => 'Edit name';

  @override
  String get settingsNameHint => 'Your name';

  @override
  String get settingsTakePhoto => 'Take Photo';

  @override
  String get settingsChooseFromGallery => 'Choose from Gallery';

  @override
  String get settingsRemovePhoto => 'Remove Photo';

  @override
  String get settingsClearTodayConfirmTitle => 'Clear today\'s entries?';

  @override
  String get settingsClearTodayConfirmBody =>
      'Soft-deletes every entry logged today (they\'re recoverable from History, same as swipe-delete) — lets you re-test things like the Insights check-in card that only show when today has nothing logged yet.';

  @override
  String get settingsClearTodaySnackbar => 'Today\'s entries cleared';

  @override
  String get settingsClearAllConfirmTitle => 'Clear every entry?';

  @override
  String get settingsClearAllConfirmBody =>
      'Permanently wipes every entry — live and already in Deleted History alike — for a genuinely clean slate. Unlike \"Clear Today\'s Entries,\" this can\'t be undone.';

  @override
  String get settingsClearAllConfirmButton => 'Clear Everything';

  @override
  String get settingsClearAllSnackbar => 'All entries cleared';

  @override
  String get settingsLogOutConfirmTitle => 'Log out?';

  @override
  String get settingsLogOutConfirmBody =>
      'You\'ll need to sign back in to see your journal.';

  @override
  String get geminiNoKeyConfigured => 'No key configured';

  @override
  String get geminiTesting => 'Testing…';

  @override
  String get geminiConnected => 'Connected';

  @override
  String get geminiConnectionFailed => 'Connection failed';

  @override
  String get geminiNotTestedYet => 'Not tested yet';

  @override
  String get geminiConnectionTitle => 'Gemini Connection';

  @override
  String get geminiTestConnectionButton => 'Test Connection';

  @override
  String get geminiApiKeyLabel => 'Gemini API Key';

  @override
  String get geminiApiKeyHint => 'Paste your API key';

  @override
  String get geminiApiKeySaveButton => 'Save';

  @override
  String get geminiApiKeySavedSnackbar => 'API key saved';

  @override
  String get geminiGetApiKeyLink => 'Get a free API key';

  @override
  String get entryShareCaption => 'My mood insight — shared with Moodlet 🌙';

  @override
  String get notificationTitle => 'Moodlet';

  @override
  String get notificationBody =>
      'How was your day? Take a moment to reflect. 🌙';

  @override
  String get notificationChannelName => 'Daily Reminder';

  @override
  String get notificationChannelDescription =>
      'A gentle daily nudge to check in with yourself.';

  @override
  String get actionNo => 'No';

  @override
  String get actionYesDelete => 'Yes, delete';

  @override
  String get deletedHistoryFullTitle => 'Deleted history is full';

  @override
  String deletedHistoryFullBody(int max) {
    return 'This day\'s History already has $max deleted entries. Restore or permanently delete some from History before deleting another.';
  }

  @override
  String get entryDeleteConfirmTitle => 'Delete entry?';

  @override
  String entryDeleteConfirmBody(String title) {
    return 'Remove \"$title\" from this day? You can restore it later from History.';
  }

  @override
  String get entryDeletedSnackbar => 'Entry deleted';

  @override
  String get entryShowLess => 'Show less';

  @override
  String get entryShowMore => 'Show more';

  @override
  String get calendarNoEntriesYet => 'No entries on this day yet.';

  @override
  String get calendarWeekdaySun => 'S';

  @override
  String get calendarWeekdayMon => 'M';

  @override
  String get calendarWeekdayTue => 'T';

  @override
  String get calendarWeekdayWed => 'W';

  @override
  String get calendarWeekdayThu => 'T';

  @override
  String get calendarWeekdayFri => 'F';

  @override
  String get calendarWeekdaySat => 'S';

  @override
  String get journalNothingLoggedYet => 'Nothing logged yet today.';

  @override
  String journalDailySlots(int count, int max) {
    return '$count of $max daily slots';
  }

  @override
  String get journalPhotosLabel => 'Photos (Optional)';

  @override
  String journalPhotosLabelCount(int count, int max) {
    return 'Photos (Optional) · $count/$max';
  }

  @override
  String get journalAddPhoto => 'Add Photo';

  @override
  String get journalAddMorePhoto => 'Add More';

  @override
  String get journalVoiceNoteButton => 'Voice Note';

  @override
  String get journalTagsLabel => 'Tags (Optional)';

  @override
  String get journalAddTagHint => 'Add a tag';

  @override
  String get journalSaveButton => 'Save Journal';

  @override
  String get journalEntrySavedSnackbar => 'Entry saved to your journal 📖';

  @override
  String journalPhotoCap(int max) {
    return 'Up to $max photos per entry';
  }

  @override
  String journalCustomTagCap(int max) {
    return 'Up to $max custom tags';
  }

  @override
  String journalDeleteConfirmBody(String title) {
    return 'Remove \"$title\" from your timeline? You can restore it later from History.';
  }

  @override
  String get journalReflectionFallback1 =>
      'What\'s one small thing that made you smile today?';

  @override
  String get journalReflectionFallback2 =>
      'What\'s something you\'re looking forward to?';

  @override
  String get journalReflectionFallback3 =>
      'Is there a moment today you\'d like to remember?';

  @override
  String get journalReflectionFallback4 =>
      'What\'s weighing on your mind right now?';

  @override
  String get journalReflectionFallback5 =>
      'What\'s one thing you\'re grateful for today?';

  @override
  String get journalReflectionFallback6 =>
      'How did you take care of yourself today?';

  @override
  String get journalReflectionFallback7 =>
      'What would make tomorrow a little better?';

  @override
  String get actionShare => 'Share';

  @override
  String get entryToday => 'Today';

  @override
  String get entryShareTagsPrefix => 'Tags: ';

  @override
  String get entrySavedSnackbar => 'Entry saved';

  @override
  String get entryRestoredSnackbar => 'Entry restored';

  @override
  String get entryNoLongerExists => 'This entry no longer exists.';

  @override
  String get entryAddVoiceNote => 'Add Voice Note';

  @override
  String entryTagCap(int max) {
    return 'Up to $max tags per entry';
  }

  @override
  String get entryNoReflectionYet =>
      'No reflection yet — start writing when you\'re ready.';

  @override
  String get entryMomentsCaptured => 'Moments Captured';

  @override
  String entryMomentsCapturedCount(int count, int max) {
    return 'Moments Captured · $count/$max';
  }

  @override
  String get entryEditTooltip => 'Edit';

  @override
  String get entryNewTagHint => 'New tag';

  @override
  String get insightsMoodJourneyTitle => 'Your Mood Journey';

  @override
  String get insightsMoodJourneySubtitle =>
      'Here\'s how you\'ve been feeling this week. Remember, every feeling is valid.';

  @override
  String insightsRecordedTimes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorded $count times recently',
      one: 'Recorded 1 time recently',
    );
    return '$_temp0';
  }

  @override
  String get insightsWelcomeBack => 'Welcome back';

  @override
  String get insightsReminderOn => 'Daily reminder turned on';

  @override
  String get insightsReminderOff => 'Daily reminder turned off';

  @override
  String get insightsReminderOnTooltip => 'Turn on daily reminder';

  @override
  String get insightsReminderOffTooltip => 'Turn off daily reminder';

  @override
  String get insightsFeelingRightNow => 'How are you feeling right now?';

  @override
  String get insightsCheckInNow => 'Check in now';

  @override
  String get insightsTrackMoodSubtitle =>
      'Track your mood to see patterns and get insights.';

  @override
  String get insightsGreetingMorning => 'Good morning';

  @override
  String get insightsGreetingAfternoon => 'Good afternoon';

  @override
  String get insightsGreetingEvening => 'Good evening';

  @override
  String get insightsGreetingNight => 'Good night';

  @override
  String get insightsLogMoreEntries =>
      'Log a few more entries with activities to see patterns.';

  @override
  String insightsCorrelationSentence(String mood, String activity) {
    return 'You feel $mood when you\n$activity';
  }

  @override
  String get insightsNoDataYet => 'No data yet';

  @override
  String get insightsLogMoodToStart => 'Log a mood to start seeing your trend.';

  @override
  String get insightsSummaryNeedMore =>
      'Log a few more moods this week to start seeing a trend.';

  @override
  String get insightsSummaryTrendingUp =>
      'Trending upward this week — nice momentum, keep it going.';

  @override
  String get insightsSummaryTougher =>
      'A tougher stretch this week — be gentle with yourself.';

  @override
  String get insightsSummaryGreatWeek =>
      'A genuinely great week overall — whatever you\'re doing, keep it up.';

  @override
  String get insightsSummaryHeavierWeek =>
      'A heavier week than usual — might be worth some extra care.';

  @override
  String get insightsSummarySteady =>
      'Pretty steady this week — nothing dramatic either way.';

  @override
  String get weeklyDetailTitle => 'Weekly Detail';

  @override
  String get weeklyMoodOverview => 'Mood Overview';

  @override
  String get weeklyDistributionTitle => 'WEEKLY DISTRIBUTION';

  @override
  String get weeklyLogMoodBreakdown =>
      'Log a mood this week to see a breakdown.';

  @override
  String weeklyMoodCount(String mood, int count) {
    return '$mood ($count)';
  }

  @override
  String get weeklyMoodPercentageTitle => 'MOOD PERCENTAGE';

  @override
  String get weeklyPositive => 'Positive';

  @override
  String get weeklyNeutral => 'Neutral';

  @override
  String get weeklyNegative => 'Negative';

  @override
  String get weeklyKeyInsightTitle => 'Key Insight';

  @override
  String get weeklyFallbackNoEntries =>
      'Log a few entries this week to start seeing patterns.';

  @override
  String get weeklyFallbackSteady =>
      'Pretty steady week — log a few more tagged entries and I\'ll start spotting real patterns.';

  @override
  String weeklyInsightPhrase(int percent, String direction, String label) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'better': 'better',
      'other': 'worse',
    });
    return '$percent% $_temp0 on days you log \"$label\"';
  }

  @override
  String get weeklyInsightTailPositive => 'worth leaning into.';

  @override
  String get weeklyInsightTailNegative => 'might be worth noticing.';

  @override
  String weeklyInsightSingle(String phrase, String tail) {
    return 'You feel $phrase — $tail';
  }

  @override
  String weeklyInsightBoth(String best, String worst) {
    return 'You feel $best, but $worst.';
  }

  @override
  String get weeklyShareIntro => 'My weekly mood detail from Moodlet 🧘';

  @override
  String weeklyShareMoodCount(String mood, int count) {
    return '$mood: $count';
  }

  @override
  String get deleteAccountTitle => 'Account Settings';

  @override
  String get deleteAccountHeading => 'Delete Account';

  @override
  String get deleteAccountBodyIntro =>
      'We\'re sad to see you go. If you delete your account, your digital sanctuary will be permanently removed. ';

  @override
  String get deleteAccountBodyBold => 'This action cannot be undone.';

  @override
  String get deleteAccountWhatYoullLose => 'What you\'ll lose';

  @override
  String get deleteAccountJournalsTitle => 'Journals';

  @override
  String get deleteAccountJournalsSubtitle =>
      'All written entries and reflections';

  @override
  String get deleteAccountMoodHistoryTitle => 'Mood History';

  @override
  String get deleteAccountMoodHistorySubtitle =>
      'Your tracked emotional journey';

  @override
  String get deleteAccountConfirmPassword =>
      'Confirm your password to continue';

  @override
  String get deleteAccountPasswordHint => 'Enter your password';

  @override
  String get deleteAccountKeepButton => 'Keep My Account';

  @override
  String get deleteAccountDeleteButton => 'Delete My Account';

  @override
  String get tourInsightsTab => 'See your mood trends and patterns here.';

  @override
  String get tourTodayTab => 'Log how you\'re feeling, right now.';

  @override
  String get tourJournalTab => 'Read and write your journal entries.';

  @override
  String get tourCalendarTab => 'Browse any past day by date.';

  @override
  String get tourAuraFab => 'Meet Aura — tap anytime for a supportive chat.';

  @override
  String get tourSettingsIcon => 'Preferences, privacy, and more live here.';

  @override
  String get settingsTakeTour => 'Take a Tour';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourNext => 'Next';

  @override
  String get tourDone => 'Got it';

  @override
  String get loadingPreparingJournal => 'Preparing your journal...';

  @override
  String get auraGreeting =>
      'Hi there! I\'m Aura, your mindful companion. How are you feeling today?';

  @override
  String get tourAuraToggle =>
      'Turn Aura on here for a supportive chat companion.';
}
