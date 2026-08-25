import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/gemini_service.dart';

/// Full-screen Aura chat, opened from the floating chat button. The
/// transcript itself lives in AppState (see [AppState.auraMessages]), not
/// local State — so closing and reopening this screen (or reloading the
/// app entirely) picks back up right where the conversation left off,
/// instead of resetting to just the opening greeting every time.
class AuraChatScreen extends StatefulWidget {
  const AuraChatScreen({super.key});

  @override
  State<AuraChatScreen> createState() => _AuraChatScreenState();
}

class _AuraChatScreenState extends State<AuraChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  // A bigger pool than what's actually shown — three of these are picked
  // at random each time the chat's opened (no AI call for this; it's just
  // a handful of static conversation starters, not worth spending Gemini
  // quota on), so the quick replies feel a little different session to
  // session instead of always being the same fixed three. Indices only
  // (not the localized text itself) are picked here, in initState, since
  // AppLocalizations needs a BuildContext that isn't safely available
  // yet — build() resolves them to actual strings each frame.
  static const _quickReplyPoolSize = 12;

  // How much of the stored conversation actually gets sent to Gemini as
  // context on each new message — see _send's own doc for why this is
  // capped instead of always sending everything.
  static const _maxHistoryTurns = 10;

  late final List<int> _quickReplyIndices =
      (List.generate(_quickReplyPoolSize, (i) => i)..shuffle()).take(3).toList();

  List<String> _quickReplyPool(AppLocalizations l10n) => [
        l10n.auraQuickReply1,
        l10n.auraQuickReply2,
        l10n.auraQuickReply3,
        l10n.auraQuickReply4,
        l10n.auraQuickReply5,
        l10n.auraQuickReply6,
        l10n.auraQuickReply7,
        l10n.auraQuickReply8,
        l10n.auraQuickReply9,
        l10n.auraQuickReply10,
        l10n.auraQuickReply11,
        l10n.auraQuickReply12,
      ];

  bool _sending = false;

  // Starts optimistic (true) so the composer is usable right away rather
  // than waiting on a network round-trip before anyone can type a single
  // character — only flips to false once _verifyKey's background check
  // actually comes back rejected. That's what lets a genuinely dead/wrong
  // key dim the composer on its own, with no need to visit Settings and
  // tap Test Connection first — this screen does that check itself, the
  // moment it opens, instead of only surfacing the problem after someone's
  // already typed and sent a message into a conversation that was never
  // going to work.
  bool _keyWorks = true;

  // Set once a reply comes back with GeminiFailureReason.dailyLimitReached
  // — see that catch clause in _send for why this dims the composer
  // rather than just showing the message inline and leaving it usable.
  bool _dailyLimitReached = false;

  // Guards _verifyKey so it only ever runs once — didChangeDependencies
  // (unlike initState) can fire more than once over this screen's
  // lifetime, and re-verifying on every single AppState change (a new
  // message arriving, etc.) would be pure waste.
  bool _keyVerifyStarted = false;

  @override
  void initState() {
    super.initState();
    // Jump straight to the most recent message on open, same as any real
    // chat app — otherwise a long-running conversation would reopen
    // scrolled to the very top.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not in initState — AppStateScope.of(context) below depends on an
    // InheritedWidget, and Flutter's own dependOnInheritedWidgetOfExactType
    // throws if that's called before initState has finished ("Uncaught
    // DartError: ... was called before _AuraChatScreenState.initState()
    // completed"). didChangeDependencies is the documented place for
    // exactly this: it always runs at least once, right after initState.
    if (!_keyVerifyStarted) {
      _keyVerifyStarted = true;
      _verifyKey();
    }
  }

  Future<void> _verifyKey() async {
    final apiKey = resolveGeminiApiKey(AppStateScope.of(context).geminiApiKey);
    // Nothing to verify — build()'s own `available` check already covers
    // the no-key case, so this just leaves the optimistic default alone.
    if (apiKey == null) return;
    try {
      await testGeminiConnection(apiKey);
    } on GeminiException catch (e) {
      if (!mounted) return;
      // Same split _send's own catch clause already makes: only a
      // genuinely rejected key (badRequest) or an already-exhausted daily
      // quota actually mean this chat can't work right now — every other
      // reason (a dropped connection, a per-minute rate limit, a
      // momentary server hiccup, an unparseable response) says nothing
      // about whether the key itself is fine, and used to disable the
      // whole composer anyway. A single bad network moment at the exact
      // instant this screen happened to open was enough to dim Aura for
      // the rest of that visit, with no retry — the only way back was
      // leaving and reopening the screen, which reset _keyWorks to true
      // and ran this same check fresh. That's exactly the "sometimes
      // works, sometimes doesn't, leaving and coming back fixes it"
      // pattern this was causing.
      switch (e.reason) {
        case GeminiFailureReason.badRequest:
          setState(() => _keyWorks = false);
        case GeminiFailureReason.dailyLimitReached:
          setState(() => _dailyLimitReached = true);
        case GeminiFailureReason.network:
        case GeminiFailureReason.rateLimited:
        case GeminiFailureReason.serverError:
        case GeminiFailureReason.badResponse:
          // Transient — leave the composer usable. If the key is
          // genuinely broken, sending a real message will surface that
          // through _send's own error handling instead.
          break;
      }
    }
  }

  // gemini_service.dart's own GeminiException.message is always plain
  // English (that file has no BuildContext to localize with), so this is
  // what actually shows a translated error inside the chat bubble instead
  // — see _send's own doc for why that mismatch was a real bug, not just
  // a cosmetic one.
  String _localizedGeminiError(AppLocalizations l10n, GeminiException e) => switch (e.reason) {
        GeminiFailureReason.network => l10n.auraErrorNetwork,
        GeminiFailureReason.badRequest => l10n.auraErrorBadRequest,
        GeminiFailureReason.dailyLimitReached => l10n.auraErrorDailyLimit,
        GeminiFailureReason.rateLimited => l10n.auraErrorRateLimited,
        GeminiFailureReason.serverError => l10n.auraErrorServer,
        GeminiFailureReason.badResponse => l10n.auraErrorBadResponse,
      };

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _confirmClear(BuildContext context, AppState appState) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.auraClearChatDialogTitle),
        content: Text(l10n.auraClearChatDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.auraClearConfirm, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) appState.clearAuraMessages();
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    final appState = AppStateScope.of(context);
    final apiKey = resolveGeminiApiKey(appState.geminiApiKey);
    // Belt-and-suspenders: the input field and send button are already
    // disabled whenever there's no key, _verifyKey found it doesn't
    // actually work, or the daily quota's already been hit (see build()
    // below), so this shouldn't be reachable that way — but guarding it
    // here too means there's no path (a stray quick-reply tap, a future
    // caller) that can still queue up a message that's just going to
    // silently go nowhere.
    if (message.isEmpty || _sending || apiKey == null || !_keyWorks || _dailyLimitReached) return;

    // History as it stood *before* this message — sendAuraMessage appends
    // the new one itself, so the two shouldn't overlap. Capped to the most
    // recent _maxHistoryTurns — Aura has no memory of anything before
    // that anyway (see sendAuraMessage's own doc), so sending the *whole*
    // conversation on every single message was pure waste once it grew
    // long: a bigger, slower request every time, for context Gemini was
    // never even asked to use. Capping it also means a long-running
    // conversation's per-message request size stays flat instead of
    // growing forever, which matters for how soon a chat can run into the
    // free tier's own per-minute/per-day quota.
    final allMessages = appState.auraMessages;
    final recentMessages = allMessages.length > _maxHistoryTurns
        ? allMessages.sublist(allMessages.length - _maxHistoryTurns)
        : allMessages;
    final history = [for (final m in recentMessages) AuraTurn(text: m.text, fromAura: m.fromAura)];
    // Captured before the await below — context isn't safe to keep
    // reading from after an async gap the way a local value is.
    final languageCode = Localizations.localeOf(context).languageCode;

    appState.addAuraMessage(AuraChatMessage(text: message, fromAura: false));
    _controller.clear();
    setState(() => _sending = true);
    _scrollToBottom();

    try {
      final reply = await sendAuraMessage(apiKey, history, message, languageCode);
      if (!mounted) return;
      appState.addAuraMessage(AuraChatMessage(text: reply, fromAura: true));
    } on GeminiException catch (e) {
      if (!mounted) return;
      // e.message itself is always plain English (gemini_service.dart has
      // no BuildContext to localize with — it's a plain service, not a
      // widget) — showing it directly used to mean an error always
      // appeared in English inside the chat bubble even on the Chinese
      // interface, unlike literally every other piece of UI text on this
      // screen. _localizedGeminiError below maps e.reason to this
      // screen's own translated copy instead, which does have access to
      // the current locale via AppLocalizations.
      appState.addAuraMessage(
        AuraChatMessage(text: _localizedGeminiError(AppLocalizations.of(context)!, e), fromAura: true),
      );
      // The daily quota won't recover until tomorrow — dimming the
      // composer for the rest of this session (same as a missing/broken
      // key) saves someone from typing into a conversation that's
      // guaranteed to fail again on every retry. Every other failure
      // reason (network hiccup, per-minute rate limit, ...) is worth
      // trying again, so only this one flips it.
      if (e.reason == GeminiFailureReason.dailyLimitReached) {
        setState(() => _dailyLimitReached = true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    // Guarded, not unconditional — _scrollToBottom touches
    // _scrollController, which is disposed the moment this screen is
    // popped; reaching this line after the send/reply await if the user
    // already backed out mid-flight would use it past that point.
    if (!mounted) return;
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final messages = appState.auraMessages;
    final quickReplies = _quickReplyIndices.map((i) => _quickReplyPool(l10n)[i]).toList();
    // No Gemini key configured — the whole composer (quick replies, text
    // field, send button) is disabled rather than letting someone type
    // and send into a chat that can only ever answer "Not available",
    // which used to waste their effort composing a message that was
    // never going anywhere.
    final available = resolveGeminiApiKey(appState.geminiApiKey) != null && _keyWorks && !_dailyLimitReached;
    // Explicit override, not the shared theme's own (now cream)
    // background — this screen reads as too "milky"/washed-out with the
    // warm cream tone behind the chat bubbles, so it keeps the original
    // cooler off-white instead of following every other screen's swap.
    const auraBackground = Color(0xFFF7F9FC);
    return Scaffold(
      backgroundColor: auraBackground,
      appBar: AppBar(
        backgroundColor: auraBackground,
        title: Row(
          children: [
            Icon(Icons.bubble_chart, color: scheme.primary),
            const SizedBox(width: 8),
            Text(l10n.auraChatTitle, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          // Hidden once there's nothing but the opening greeting left —
          // no point offering to clear a chat that's already effectively
          // empty.
          if (messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.auraClearChatTooltip,
              onPressed: () => _confirmClear(context, appState),
            ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).maybePop()),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) return const _TypingBubble();
                return _Bubble(message: messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => OutlinedButton(
                        onPressed: _sending || !available ? null : () => _send(quickReplies[index]),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.outlineVariant),
                          foregroundColor: scheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(quickReplies[index]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.surfaceContainerHighest),
                      boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.08), blurRadius: 20)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_sending && available,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              filled: false,
                              hintText: available ? l10n.auraTypeMessageHint : l10n.auraNotAvailableHint,
                            ),
                            onSubmitted: _send,
                          ),
                        ),
                        IconButton(
                          onPressed: _sending || !available ? null : () => _send(),
                          icon: Icon(Icons.send, color: available ? scheme.onPrimary : scheme.onSurfaceVariant),
                          style: IconButton.styleFrom(
                            backgroundColor: available ? scheme.primary : scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final AuraChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = message.fromAura ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bubbleColor = message.fromAura ? scheme.primaryFixed : scheme.tertiaryFixed;
    final textColor = message.fromAura ? scheme.onPrimaryFixed : scheme.onTertiaryFixed;
    final radius = message.fromAura
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: message.fromAura ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (message.fromAura) ...[
                CircleAvatar(radius: 14, backgroundColor: scheme.primaryContainer, child: Icon(Icons.bubble_chart, size: 14, color: scheme.primary)),
                const SizedBox(width: 8),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
                  child: Text(
                    // The opening greeting is always stored in fixed
                    // English (see AppState.defaultAuraGreeting's doc) —
                    // every other message here is either something the
                    // user actually typed themselves, or a live Gemini
                    // reply already generated in the current language
                    // (see sendAuraMessage), so only this one exact
                    // string needs a display-time swap.
                    message.text == defaultAuraGreeting
                        ? AppLocalizations.of(context)!.auraGreeting
                        : message.text,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stand-in "Aura is typing…" bubble shown while waiting on Gemini —
/// same shape/side as a real Aura bubble so it doesn't jump when the
/// actual reply replaces it.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 14, backgroundColor: scheme.primaryContainer, child: Icon(Icons.bubble_chart, size: 14, color: scheme.primary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.primaryFixed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimaryFixed),
            ),
          ),
        ],
      ),
    );
  }
}
