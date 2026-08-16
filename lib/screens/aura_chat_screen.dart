import 'package:flutter/material.dart';
import '../data/app_state.dart';
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
  // session instead of always being the same fixed three.
  static const _quickReplyPool = [
    'I need to vent',
    'Breathing exercise',
    'Just chatting',
    'Help me reflect on today',
    "I'm feeling anxious",
    'Celebrate a win with me',
    "I'm feeling great today",
    'Give me a journal prompt',
    'I need some encouragement',
    'Help me unwind',
    "I'm feeling stuck",
    'Something to be grateful for',
  ];

  late final List<String> _quickReplies = (List.of(_quickReplyPool)..shuffle()).take(3).toList();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Jump straight to the most recent message on open, same as any real
    // chat app — otherwise a long-running conversation would reopen
    // scrolled to the very top.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
  }

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text("This conversation with Aura will be cleared. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
    // disabled whenever there's no key (see build() below), so this
    // shouldn't be reachable that way — but guarding it here too means
    // there's no path (a stray quick-reply tap, a future caller) that can
    // still queue up a message that's just going to silently go nowhere.
    if (message.isEmpty || _sending || apiKey == null) return;

    // History as it stood *before* this message — sendAuraMessage appends
    // the new one itself, so the two shouldn't overlap.
    final history = [for (final m in appState.auraMessages) AuraTurn(text: m.text, fromAura: m.fromAura)];

    appState.addAuraMessage(AuraChatMessage(text: message, fromAura: false));
    _controller.clear();
    setState(() => _sending = true);
    _scrollToBottom();

    try {
      final reply = await sendAuraMessage(apiKey, history, message);
      if (!mounted) return;
      appState.addAuraMessage(AuraChatMessage(text: reply, fromAura: true));
    } on GeminiException catch (e) {
      if (!mounted) return;
      // e.message is already a complete, friendly sentence — no need to
      // wrap it in another "sorry, I couldn't..." on top of it.
      appState.addAuraMessage(AuraChatMessage(text: e.message, fromAura: true));
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
    final appState = AppStateScope.of(context);
    final messages = appState.auraMessages;
    // No Gemini key configured — the whole composer (quick replies, text
    // field, send button) is disabled rather than letting someone type
    // and send into a chat that can only ever answer "Not available",
    // which used to waste their effort composing a message that was
    // never going anywhere.
    final available = resolveGeminiApiKey(appState.geminiApiKey) != null;
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
            Text('Aura AI', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          // Hidden once there's nothing but the opening greeting left —
          // no point offering to clear a chat that's already effectively
          // empty.
          if (messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
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
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => OutlinedButton(
                        onPressed: _sending || !available ? null : () => _send(_quickReplies[index]),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.outlineVariant),
                          foregroundColor: scheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(_quickReplies[index]),
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
                              hintText: available ? 'Type a message...' : 'Currently not available for chat',
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
                  child: Text(message.text, style: TextStyle(color: textColor)),
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
