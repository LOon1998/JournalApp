// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navInsights => '洞察';

  @override
  String get navToday => '今天';

  @override
  String get navJournal => '日记';

  @override
  String get navCalendar => '日历';

  @override
  String get moodGreat => '很棒';

  @override
  String get moodGood => '不错';

  @override
  String get moodOkay => '一般';

  @override
  String get moodSad => '难过';

  @override
  String get moodAwful => '很糟';

  @override
  String get actionSave => '保存';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionDone => '完成';

  @override
  String get actionContinue => '继续';

  @override
  String get actionClose => '关闭';

  @override
  String get todayHeadline => '你今天感觉怎么样？';

  @override
  String get todayActivitiesTitle => '你今天做了什么？';

  @override
  String get activityWork => '工作';

  @override
  String get activityFamily => '家人';

  @override
  String get activityFriends => '朋友';

  @override
  String get activityHobby => '爱好';

  @override
  String get activityExercise => '运动';

  @override
  String get activitySleep => '睡眠';

  @override
  String get activityOther => '其他';

  @override
  String get activityHealth => '健康';

  @override
  String get continueWriteJournal => '继续并撰写\n日记';

  @override
  String get saveMoodOnly => '仅保存心情';

  @override
  String get journalTodaysEntries => '今日记录';

  @override
  String get journalHistory => '历史记录';

  @override
  String get journalDailyReflection => '每日反思';

  @override
  String get journalReflectionTitle => '日记反思';

  @override
  String get journalWritingTheme => '写作主题';

  @override
  String get journalTitleFieldLabel => '日记标题（可选）';

  @override
  String get journalTitleHint => '为你的日记命名...';

  @override
  String get journalWriteHint => '在这里写下你的想法...';

  @override
  String get journalFeelingLabel => '心情：';

  @override
  String get insightsMoodPattern => '心情模式';

  @override
  String get insightsLast7Days => '最近7天';

  @override
  String get insightsKeyTakeaway => '重点总结';

  @override
  String get insightsMostFrequent => '最常见';

  @override
  String get insightsWhatAffectsYourMood => '影响你心情的因素';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsNotificationsBlockedByOs =>
      '已在手机系统设置中被屏蔽——请先在系统设置中为 Moodlet 开启通知权限。';

  @override
  String get settingsOpenSystemNotificationSettings => '打开通知设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsPrivacySecurity => '隐私与安全';

  @override
  String get settingsHelpSupport => '帮助与支持';

  @override
  String get settingsAboutLumina => '关于 Moodlet';

  @override
  String get settingsLogOut => '退出登录';

  @override
  String get actionRemove => '移除';

  @override
  String get actionStartOver => '重新开始';

  @override
  String get actionOk => '好的';

  @override
  String get welcomeTitle => '一切就绪，朋友！';

  @override
  String get welcomeSubtitle => '欢迎来到你的全新数字港湾——一个只属于你自己的私密空间。准备好了，就为自己留一点时间吧。';

  @override
  String get welcomeStartButton => '开始我的第一次打卡';

  @override
  String get appLockIncorrectPattern => '图案不正确，请重试';

  @override
  String get appLockDrawToUnlock => '绘制图案以解锁';

  @override
  String get patternLockSetupTitle => '设置图案锁';

  @override
  String get patternLockDrawNew => '绘制一个新图案';

  @override
  String get patternLockConnectDots => '至少连接2个点，请重试';

  @override
  String get patternLockDrawAgainConfirm => '再次绘制图案以确认';

  @override
  String get patternLockDidntMatch => '图案不匹配，请绘制新图案';

  @override
  String get patternLockSetSnackbar => '图案锁已设置';

  @override
  String get helpSupportHeroTitle => '我们随时为你提供帮助';

  @override
  String get helpSupportHeroSubtitle => '下面是一些常见问题解答。';

  @override
  String get helpSupportFaqTitle => '常见问题';

  @override
  String get helpSupportFaq1Q => '我的数据安全吗？';

  @override
  String get helpSupportFaq1A =>
      '是的——你的账户和日记受 Firebase Authentication 和 Cloud Firestore 保护，访问规则限制只有你自己登录的账户才能访问你的数据。完整详情请见隐私政策（关于 Moodlet）。';

  @override
  String get helpSupportFaq2Q => '我可以在多台设备上使用 Moodlet 吗？';

  @override
  String get helpSupportFaq2A =>
      '可以——在任意设备上用同一账户登录，你的日记、心情记录和设置都会同步呈现。图案锁是唯一的例外——它是按设备单独设置的，所以在新设备上需要重新设置。';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String privacyPolicyLastUpdated(String date) {
    return '最后更新：$date';
  }

  @override
  String get privacyPolicyOverviewTitle => '概述';

  @override
  String get privacyPolicyOverviewBody =>
      'Moodlet（\"我们\"、\"本应用\"）是一款个人日记应用。本政策说明了本应用收集哪些信息、如何使用这些信息，以及你可以做出的选择。使用 Moodlet 即表示你同意此处所述的做法。';

  @override
  String get privacyPolicyInfoCollectTitle => '我们收集的信息';

  @override
  String get privacyPolicyInfoCollectBody =>
      '• 账户信息：你注册时使用的电子邮件地址和密码（你的密码对我们不可见——由 Firebase Authentication 直接处理）。\n• 你选择添加的个人资料信息：显示名称和/或头像。\n• 日记内容：你写下的任何内容、记录的心情和标签/活动，以及附加到条目中的任何照片或语音记录。\n• 可选的 AI 密钥：如果你在设置中选择连接自己的 Google Gemini API 密钥以使用 AI 功能，该密钥会被保存以便应用使用——详见下方\"可选的 AI 功能\"。\n\n我们不收集分析数据、广告标识符或位置信息，Moodlet 不含任何广告或第三方追踪器。';

  @override
  String get privacyPolicyStorageTitle => '我们如何存储你的信息';

  @override
  String get privacyPolicyStorageBody =>
      '你的账户和日记数据通过 Firebase Authentication 和 Cloud Firestore（Google Cloud 基础设施）存储，传输过程中经过加密。访问规则将你的数据限制为仅你自己登录的账户可访问——其他用户无法读取或写入。设备上也会缓存一份副本以支持离线使用；删除账户时该本地副本会被清除。';

  @override
  String get privacyPolicyUseTitle => '我们如何使用你的信息';

  @override
  String get privacyPolicyUseBody =>
      '• 创建并保护你的账户，让你可以在任意设备上重新登录。\n• 存储并同步你的日记条目，以便你每次打开应用时都能看到它们。\n• 在应用内（洞察）向你展示你自己的心情趋势和模式。\n• 如果你开启每日提醒，则发送可选的本地通知——该提醒完全在你的设备上安排，不涉及任何数据的发送。\n\n我们不会将你的日记内容用于广告，也不会将你的信息出售给任何人。';

  @override
  String get privacyPolicyAiTitle => '可选的 AI 功能';

  @override
  String get privacyPolicyAiBody =>
      'Moodlet 可以使用 Google Gemini API 来建议反思提示、优化你的每周心情趋势，或为条目生成标题——但前提是你在设置中提供了自己的 Gemini API 密钥。如果你这样做，相关的条目文本会被直接发送到 Google 的 Gemini API 以生成该回复，并受 Google 自身隐私条款的约束。如果未设置密钥，则不会发生上述任何情况，也不会有任何日记内容因此离开你的设备。';

  @override
  String get privacyPolicySecurityTitle => '设备端安全功能';

  @override
  String get privacyPolicySecurityBody =>
      '图案锁（设置 → 隐私与安全）仅存储在你的设备上，绝不会同步到我们的服务器或对我们可见——绘制的图案仅以不可逆的哈希形式存储，绝不会以可被读取的形式保存。';

  @override
  String get privacyPolicyRetentionTitle => '数据保留与删除';

  @override
  String get privacyPolicyRetentionBody =>
      '只要你的账户存在，你的数据就会被保留。从时间线中删除一条记录会先将其移至\"历史记录\"，在有限时间内可供恢复，之后才会被永久删除，这样如果是误删你还可以恢复。你可以随时在设置 → 删除账户中永久删除你的整个账户及所有相关数据——此操作会立即且永久地删除你的日记数据、本地设备缓存以及账户本身。';

  @override
  String get privacyPolicyChildrenTitle => '儿童隐私';

  @override
  String get privacyPolicyChildrenBody =>
      'Moodlet 并非面向13岁以下儿童，我们也不会在知情的情况下收集任何该年龄以下人士的信息。如果你认为某位儿童向我们提供了个人信息，请通过下方联系方式与我们联系，我们会将其删除。';

  @override
  String get privacyPolicyChangesTitle => '本政策的变更';

  @override
  String get privacyPolicyChangesBody =>
      '如果本政策发生变更，本页顶部的\"最后更新\"日期也会随之更新。变更后继续使用 Moodlet 即表示你接受修订后的政策。';

  @override
  String get privacyPolicyContactTitle => '联系我们';

  @override
  String privacyPolicyContactBody(String email) {
    return '对本政策或你的数据有疑问？请通过 $email 联系我们。';
  }

  @override
  String get changePasswordTitle => '修改密码';

  @override
  String get changePasswordSuccessSnackbar => '密码已修改';

  @override
  String get changePasswordCurrentLabel => '当前密码';

  @override
  String get changePasswordCurrentValidator => '请输入你的当前密码';

  @override
  String get changePasswordNewLabel => '新密码';

  @override
  String get changePasswordNewHelper => '至少需要6个字符。';

  @override
  String get changePasswordNewValidatorEmpty => '请输入新密码';

  @override
  String get changePasswordNewValidatorLength => '至少需要6个字符';

  @override
  String get changePasswordNewValidatorSame => '请选择与当前密码不同的新密码';

  @override
  String get changePasswordConfirmLabel => '确认新密码';

  @override
  String get changePasswordConfirmValidatorMismatch => '两次输入的密码不一致';

  @override
  String get privacySecurityIntro => '让你的日记只属于你——保护你的账户，并在此设备上锁定应用。';

  @override
  String get privacySecurityAccountSecurity => '账户安全';

  @override
  String get privacySecurityPatternLockRow => '图案锁';

  @override
  String get privacySecurityOn => '已开启';

  @override
  String get privacySecurityNotSet => '未设置';

  @override
  String get privacySecurityChangePattern => '更改图案';

  @override
  String get privacySecurityRemovePattern => '移除图案';

  @override
  String get privacySecurityRemoveDialogTitle => '移除图案锁？';

  @override
  String get privacySecurityRemoveDialogBody => '之后打开 Moodlet 将不再需要输入图案。';

  @override
  String get privacySecurityPatternRemovedSnackbar => '图案锁已移除';

  @override
  String get aboutHeroTitle => '你的数字避风港';

  @override
  String get aboutHeroBody =>
      'Moodlet 的诞生，是为了打造一个安全、不带评判的情绪反思空间。我们相信，为自己留一点时间不该是一件苦差事，而应是一种温柔的自我关怀习惯。在这里，你可以停下脚步，深呼吸，在一个为静心成长而设计的宁静空间中理清思绪。';

  @override
  String get aboutCoreValuesTitle => '我们的核心价值';

  @override
  String get aboutValuePrivacyTitle => '隐私至上';

  @override
  String get aboutValuePrivacyBody =>
      '你的心声完全属于你自己。你的日记存储在你自己的私人账户中，绝不会被分享或出售，你也可以随时彻底删除它。';

  @override
  String get aboutValueGrowthTitle => '静心成长';

  @override
  String get aboutValueGrowthBody =>
      '我们致力于设计能培养温和自我觉察的互动方式，避免让人上瘾的循环，转而鼓励有意义、用心的打卡。';

  @override
  String get aboutValueCreativeTitle => '自由表达';

  @override
  String get aboutValueCreativeBody =>
      '一块属于你情绪的自由画布——文字、心情色彩、照片、语音记录和标签——让你的感受以任何合适的方式呈现。';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String aboutCopyright(int year) {
    return '© $year Moodlet Journal。保留所有权利。';
  }

  @override
  String entryFeelingMood(String mood) {
    return '感觉$mood';
  }

  @override
  String get insightsNoneYet => '暂无';

  @override
  String get todayPickMoodFirst => '请先选择一个心情 🙂';

  @override
  String todayEntryLimitSnackbar(int limit) {
    return '今日 $limit 条记录已达上限——删除一条才能再添加。';
  }

  @override
  String todayEntryLimitBanner(int limit) {
    return '今日 $limit 条记录已达上限。';
  }

  @override
  String get todayMoodSaved => '心情已保存到你的日记 📖';

  @override
  String todayCustomActivityCap(int max) {
    return '最多可添加 $max 个自定义活动';
  }

  @override
  String get todayCustomActivityHint => '还有什么？';

  @override
  String get editEntryTitle => '编辑记录';

  @override
  String get editEntryTagsLabel => '标签';

  @override
  String get editEntrySaveChanges => '保存更改';

  @override
  String get deletedEntriesTitle => '已删除记录';

  @override
  String get deletedEntriesClearAll => '清空全部';

  @override
  String deletedEntriesSlotsUsed(int count, int max) {
    return '已用 $count/$max 个删除位';
  }

  @override
  String deletedEntriesExpiryNote(int days) {
    return '已删除的记录将在 $days 天后被永久移除。';
  }

  @override
  String get deletedEntriesPrevPage => '上一页';

  @override
  String get deletedEntriesNextPage => '下一页';

  @override
  String get deletedEntriesConfirmClearAllTitle => '永久删除全部？';

  @override
  String deletedEntriesConfirmClearAllBody(num count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这将永久删除来自 $date 的全部 $count 条已删除记录，此操作无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get deletedEntriesDeleteAll => '全部删除';

  @override
  String get deletedEntriesEmptyTitle => '没有已删除的记录';

  @override
  String deletedEntriesEmptyBody(String date) {
    return '$date 没有已删除的内容。你删除的记录会显示在这里，方便你恢复或彻底移除它们。';
  }

  @override
  String get deletedEntriesBadge => '已删除';

  @override
  String get deletedEntriesRestore => '恢复';

  @override
  String get deletedEntriesDeleteForever => '永久删除';

  @override
  String get deletedEntriesCantRestoreTitle => '无法恢复';

  @override
  String deletedEntriesCantRestoreBody(String date, int max) {
    return '$date 已有 $max 条记录——请先删除该日的一条记录，再恢复这条。';
  }

  @override
  String get deletedEntriesDeleteForeverConfirmTitle => '永久删除？';

  @override
  String deletedEntriesDeleteForeverConfirmBody(String title) {
    return '\"$title\" 将被永久移除，此操作无法撤销。';
  }

  @override
  String get authCreateAccount => '创建账户';

  @override
  String get authJoinSubtitle => '加入 Moodlet，开启你的写作之旅。';

  @override
  String get authSignInSubtitle => '登录以继续你的静心之旅。';

  @override
  String get authAddPhoto => '添加照片';

  @override
  String get authChangePhoto => '更换照片';

  @override
  String get authEmailLabel => '邮箱';

  @override
  String get authEmailEmptyValidator => '请输入你的邮箱';

  @override
  String get authEmailInvalidValidator => '请输入有效的邮箱地址';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authPasswordHelper => '至少需要6个字符。';

  @override
  String get authPasswordEmptyValidator => '请输入你的密码';

  @override
  String get authPasswordLengthValidator => '至少需要6个字符';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authSignIn => '登录';

  @override
  String get authAlreadyHaveAccount => '已经有账户了？';

  @override
  String get authDontHaveAccount => '还没有账户？';

  @override
  String get authSignUp => '注册';

  @override
  String get authQuickTestSignIn => '快速测试登录';

  @override
  String get authForgotPasswordNeedEmail => '请先在上方输入你的邮箱，然后再次点击\"忘记密码？\"。';

  @override
  String authPasswordResetSent(String email) {
    return '密码重置邮件已发送至 $email——如果没有收到，请检查垃圾邮件文件夹。';
  }

  @override
  String get authRememberMe => '记住我';

  @override
  String get auraChatTitle => 'Aura AI';

  @override
  String get auraClearChatTooltip => '清空对话';

  @override
  String get auraClearChatDialogTitle => '清空对话？';

  @override
  String get auraClearChatDialogBody => '与 Aura 的这段对话记录将被清空，此操作无法撤销。';

  @override
  String get auraClearConfirm => '清空';

  @override
  String get auraTypeMessageHint => '输入消息...';

  @override
  String get auraNotAvailableHint => '当前无法进行对话';

  @override
  String get auraErrorNetwork => '无法连接到Aura——请检查网络连接后重试。';

  @override
  String get auraErrorBadRequest => 'Aura设置有误——请在设置中检查你的API密钥。';

  @override
  String get auraErrorDailyLimit => '暂不可用——今日使用额度已用完，请明天再试。';

  @override
  String get auraErrorRateLimited => 'Aura现在有点忙——请几分钟后再试。';

  @override
  String get auraErrorServer => '暂时不可用，请稍后再试。';

  @override
  String get auraErrorBadResponse => '无法读取Aura的回复，请稍后再试。';

  @override
  String get auraQuickReply1 => '我想倾诉一下';

  @override
  String get auraQuickReply2 => '呼吸练习';

  @override
  String get auraQuickReply3 => '随便聊聊';

  @override
  String get auraQuickReply4 => '帮我回顾一下今天';

  @override
  String get auraQuickReply5 => '我感到焦虑';

  @override
  String get auraQuickReply6 => '陪我庆祝一件小成就';

  @override
  String get auraQuickReply7 => '我今天感觉很棒';

  @override
  String get auraQuickReply8 => '给我一个写作灵感';

  @override
  String get auraQuickReply9 => '我需要一些鼓励';

  @override
  String get auraQuickReply10 => '帮我放松一下';

  @override
  String get auraQuickReply11 => '我感觉卡住了';

  @override
  String get auraQuickReply12 => '说说值得感恩的事';

  @override
  String entriesHistoryCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记录',
    );
    return '$_temp0';
  }

  @override
  String get voiceNoteLabel => '语音记录';

  @override
  String get topBarHideAura => '隐藏 Aura 伙伴';

  @override
  String get topBarShowAura => '显示 Aura 伙伴';

  @override
  String get voiceRecorderMicPermissionDenied => '未获得麦克风权限。';

  @override
  String voiceRecorderStartError(String error) {
    return '无法开始录音：$error';
  }

  @override
  String voiceRecorderSaveError(String error) {
    return '无法保存录音：$error';
  }

  @override
  String get voiceRecorderMaxDuration => '最长60秒';

  @override
  String get voiceRecorderStopSave => '停止并保存';

  @override
  String get auraHintBubble => '想聊聊吗？我在这里陪着你。';

  @override
  String get actionClear => '清空';

  @override
  String get settingsSubtitle => '定制你的专属港湾。';

  @override
  String get settingsEditPhoto => '编辑照片';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsLight => '浅色';

  @override
  String get settingsDark => '深色';

  @override
  String get settingsAiCompanion => 'AI 伙伴';

  @override
  String get settingsEnableAura => '启用 Aura';

  @override
  String get settingsEnableAuraSubtitle => '让悬浮的 Aura 聊天机器人陪伴你。';

  @override
  String get settingsTestingTools => '测试工具';

  @override
  String get settingsTestingToolsSubtitle => '并非正式功能——仅用于方便测试今日 UI 状态。';

  @override
  String get settingsClearTodayButton => '清空今日记录';

  @override
  String get settingsFillPastWeek => '填充过去7天';

  @override
  String get settingsFillPastWeekSnackbar => '已添加一周的测试记录';

  @override
  String get settingsClearAllButton => '清空全部记录';

  @override
  String get settingsTestNotification => '测试通知';

  @override
  String get settingsTestNotificationSnackbar => '测试通知已发送——请检查通知栏';

  @override
  String get settingsTestNotificationDisabledSnackbar => '请先打开上方的通知开关';

  @override
  String get settingsDeleteAccount => '删除账户';

  @override
  String get settingsEditNameDialogTitle => '编辑姓名';

  @override
  String get settingsNameHint => '你的姓名';

  @override
  String get settingsTakePhoto => '拍照';

  @override
  String get settingsChooseFromGallery => '从相册选择';

  @override
  String get settingsRemovePhoto => '移除照片';

  @override
  String get settingsClearTodayConfirmTitle => '清空今日记录？';

  @override
  String get settingsClearTodayConfirmBody =>
      '软删除今天记录的所有条目（可从历史记录中恢复，与滑动删除相同）——方便你重新测试像\"仅当今天尚无记录时才显示\"的洞察打卡卡片等功能。';

  @override
  String get settingsClearTodaySnackbar => '今日记录已清空';

  @override
  String get settingsClearAllConfirmTitle => '清空全部记录？';

  @override
  String get settingsClearAllConfirmBody =>
      '永久清除所有记录——包括当前的和已在删除历史中的——彻底清空。与\"清空今日记录\"不同，此操作无法撤销。';

  @override
  String get settingsClearAllConfirmButton => '清空全部';

  @override
  String get settingsClearAllSnackbar => '全部记录已清空';

  @override
  String get settingsLogOutConfirmTitle => '退出登录？';

  @override
  String get settingsLogOutConfirmBody => '你需要重新登录才能查看你的日记。';

  @override
  String get entryShareCaption => '我的心情记录 —— 通过 Moodlet 分享 🌙';

  @override
  String get notificationTitle => 'Moodlet';

  @override
  String get notificationBody => '今天过得怎么样？花一点时间回顾一下吧。🌙';

  @override
  String get notificationChannelName => '每日提醒';

  @override
  String get notificationChannelDescription => '温柔地提醒你每天花点时间关心自己。';

  @override
  String get actionNo => '否';

  @override
  String get actionYesDelete => '是，删除';

  @override
  String get deletedHistoryFullTitle => '已删除历史已满';

  @override
  String deletedHistoryFullBody(int max) {
    return '这一天的历史记录中已有 $max 条已删除条目。请先从历史记录中恢复或永久删除一些，再删除另一条。';
  }

  @override
  String get entryDeleteConfirmTitle => '删除记录？';

  @override
  String entryDeleteConfirmBody(String title) {
    return '从这一天移除\"$title\"？之后仍可从历史记录中恢复。';
  }

  @override
  String get entryDeletedSnackbar => '记录已删除';

  @override
  String get entryShowLess => '收起';

  @override
  String get entryShowMore => '展开';

  @override
  String get calendarNoEntriesYet => '这一天还没有记录。';

  @override
  String get calendarWeekdaySun => '日';

  @override
  String get calendarWeekdayMon => '一';

  @override
  String get calendarWeekdayTue => '二';

  @override
  String get calendarWeekdayWed => '三';

  @override
  String get calendarWeekdayThu => '四';

  @override
  String get calendarWeekdayFri => '五';

  @override
  String get calendarWeekdaySat => '六';

  @override
  String get journalNothingLoggedYet => '今天还没有记录。';

  @override
  String journalDailySlots(int count, int max) {
    return '已用 $count/$max 个每日名额';
  }

  @override
  String get journalPhotosLabel => '照片（可选）';

  @override
  String journalPhotosLabelCount(int count, int max) {
    return '照片（可选）· $count/$max';
  }

  @override
  String get journalAddPhoto => '添加照片';

  @override
  String get journalAddMorePhoto => '添加更多';

  @override
  String get journalVoiceNoteButton => '语音记录';

  @override
  String get journalTagsLabel => '标签（可选）';

  @override
  String get journalAddTagHint => '添加标签';

  @override
  String get journalSaveButton => '保存日记';

  @override
  String get journalEntrySavedSnackbar => '记录已保存到你的日记 📖';

  @override
  String journalPhotoCap(int max) {
    return '每条记录最多 $max 张照片';
  }

  @override
  String journalCustomTagCap(int max) {
    return '最多可添加 $max 个自定义标签';
  }

  @override
  String journalDeleteConfirmBody(String title) {
    return '从时间线中移除\"$title\"？之后仍可从历史记录中恢复。';
  }

  @override
  String get journalReflectionFallback1 => '今天有什么小事让你会心一笑？';

  @override
  String get journalReflectionFallback2 => '有什么事让你期待？';

  @override
  String get journalReflectionFallback3 => '今天有什么想要记住的瞬间吗？';

  @override
  String get journalReflectionFallback4 => '现在有什么事压在你心头？';

  @override
  String get journalReflectionFallback5 => '今天有什么值得感恩的事？';

  @override
  String get journalReflectionFallback6 => '今天你是怎么照顾自己的？';

  @override
  String get journalReflectionFallback7 => '怎样能让明天更好一点？';

  @override
  String get actionShare => '分享';

  @override
  String get entryToday => '今天';

  @override
  String get entryShareTagsPrefix => '标签：';

  @override
  String get entrySavedSnackbar => '记录已保存';

  @override
  String get entryRestoredSnackbar => '记录已恢复';

  @override
  String get entryNoLongerExists => '这条记录已不存在。';

  @override
  String get entryAddVoiceNote => '添加语音记录';

  @override
  String entryTagCap(int max) {
    return '每条记录最多 $max 个标签';
  }

  @override
  String get entryNoReflectionYet => '还没有反思内容——准备好了就开始写吧。';

  @override
  String get entryMomentsCaptured => '珍贵瞬间';

  @override
  String entryMomentsCapturedCount(int count, int max) {
    return '珍贵瞬间 · $count/$max';
  }

  @override
  String get entryEditTooltip => '编辑';

  @override
  String get entryNewTagHint => '新标签';

  @override
  String get insightsMoodJourneyTitle => '你的心情历程';

  @override
  String get insightsMoodJourneySubtitle => '这是你这一周的心情变化。记住，每一种感受都值得被理解。';

  @override
  String insightsRecordedTimes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最近记录了 $count 次',
    );
    return '$_temp0';
  }

  @override
  String get insightsWelcomeBack => '欢迎回来';

  @override
  String get insightsReminderOn => '每日提醒已开启';

  @override
  String get insightsReminderOff => '每日提醒已关闭';

  @override
  String get insightsReminderOnTooltip => '开启每日提醒';

  @override
  String get insightsReminderOffTooltip => '关闭每日提醒';

  @override
  String get insightsFeelingRightNow => '你现在感觉怎么样？';

  @override
  String get insightsCheckInNow => '立即打卡';

  @override
  String get insightsTrackMoodSubtitle => '记录你的心情，发现规律，获得洞察。';

  @override
  String get insightsGreetingMorning => '早上好';

  @override
  String get insightsGreetingAfternoon => '下午好';

  @override
  String get insightsGreetingEvening => '晚上好';

  @override
  String get insightsGreetingNight => '夜深了';

  @override
  String get insightsLogMoreEntries => '记录更多带活动标签的条目，才能看到规律。';

  @override
  String insightsCorrelationSentence(String mood, String activity) {
    return '当你$activity时，你感觉$mood';
  }

  @override
  String get insightsNoDataYet => '暂无数据';

  @override
  String get insightsLogMoodToStart => '记录一次心情，开始查看你的趋势。';

  @override
  String get insightsSummaryNeedMore => '本周再多记录几次心情，才能开始看到趋势。';

  @override
  String get insightsSummaryTrendingUp => '本周呈上升趋势——势头不错，继续保持。';

  @override
  String get insightsSummaryTougher => '本周有点辛苦——请对自己温柔一些。';

  @override
  String get insightsSummaryGreatWeek => '这一整周都相当不错——无论你在做什么，请继续保持。';

  @override
  String get insightsSummaryHeavierWeek => '这周比平时更沉重一些——或许值得多一些自我关怀。';

  @override
  String get insightsSummarySteady => '本周相当平稳——没有太大起伏。';

  @override
  String get weeklyDetailTitle => '每周详情';

  @override
  String get weeklyMoodOverview => '心情概览';

  @override
  String get weeklyDistributionTitle => '每周分布';

  @override
  String get weeklyLogMoodBreakdown => '本周记录一次心情，即可查看分布情况。';

  @override
  String weeklyMoodCount(String mood, int count) {
    return '$mood（$count）';
  }

  @override
  String get weeklyMoodPercentageTitle => '心情占比';

  @override
  String get weeklyPositive => '积极';

  @override
  String get weeklyNeutral => '中性';

  @override
  String get weeklyNegative => '消极';

  @override
  String get weeklyKeyInsightTitle => '重点洞察';

  @override
  String get weeklyFallbackNoEntries => '本周记录几条内容，即可开始查看规律。';

  @override
  String get weeklyFallbackSteady => '本周相当平稳——多记录几条带标签的内容，我就能开始发现真正的规律。';

  @override
  String weeklyInsightPhrase(int percent, String direction, String label) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'better': '更好',
      'other': '更差',
    });
    return '在记录\"$label\"的日子里，你的心情$_temp0 $percent%';
  }

  @override
  String get weeklyInsightTailPositive => '值得多做一些。';

  @override
  String get weeklyInsightTailNegative => '或许值得留意一下。';

  @override
  String weeklyInsightSingle(String phrase, String tail) {
    return '$phrase——$tail';
  }

  @override
  String weeklyInsightBoth(String best, String worst) {
    return '$best，但也$worst。';
  }

  @override
  String get weeklyShareIntro => '我在 Moodlet 上的每周心情详情 🧘';

  @override
  String weeklyShareMoodCount(String mood, int count) {
    return '$mood：$count';
  }

  @override
  String get deleteAccountTitle => '账户设置';

  @override
  String get deleteAccountHeading => '删除账户';

  @override
  String get deleteAccountBodyIntro => '很遗憾看到你离开。删除账户后，你的专属港湾将被永久移除。';

  @override
  String get deleteAccountBodyBold => '此操作无法撤销。';

  @override
  String get deleteAccountWhatYoullLose => '你将失去';

  @override
  String get deleteAccountJournalsTitle => '日记';

  @override
  String get deleteAccountJournalsSubtitle => '所有写下的记录与反思';

  @override
  String get deleteAccountMoodHistoryTitle => '心情历史';

  @override
  String get deleteAccountMoodHistorySubtitle => '你所记录的情绪历程';

  @override
  String get deleteAccountConfirmPassword => '请输入密码以继续';

  @override
  String get deleteAccountPasswordHint => '输入你的密码';

  @override
  String get deleteAccountKeepButton => '保留我的账户';

  @override
  String get deleteAccountDeleteButton => '删除我的账户';

  @override
  String get tourInsightsTab => '在这里查看你的心情趋势和规律';

  @override
  String get tourTodayTab => '记录你此刻的感受';

  @override
  String get tourJournalTab => '阅读和撰写你的日记';

  @override
  String get tourCalendarTab => '按日期浏览过去的任意一天';

  @override
  String get tourAuraFab => '认识 Aura——随时点击开启暖心对话';

  @override
  String get tourSettingsIcon => '偏好设置、隐私等都在这里';

  @override
  String get settingsTakeTour => '开始导览';

  @override
  String get tourSkip => '跳过';

  @override
  String get tourNext => '下一步';

  @override
  String get tourDone => '知道了';

  @override
  String get loadingPreparingJournal => '正在准备你的日记...';

  @override
  String get auraGreeting => '你好！我是 Aura，你的贴心伙伴。你今天感觉怎么样？';

  @override
  String get tourAuraToggle => '在这里开启 Aura，获得一个贴心的聊天伙伴。';
}
