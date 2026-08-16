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

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty || _sending) return;

    final appState = AppStateScope.of(context);
    final apiKey = resolveGeminiApiKey(appState.geminiApiKey);
    // History as it stood *before* this message — sendAuraMessage appends
    // the new one itself, so the two shouldn't overlap.
    final history = [for (final m in appState.auraMessages) AuraTurn(text: m.text, fromAura: m.fromAura)];

    appState.addAuraMessage(AuraChatMessage(text: message, fromAura: false));
    _controller.clear();
    if (apiKey != null) setState(() => _sending = true);
    _scrollToBottom();

    if (apiKey == null) {
      appState.addAuraMessage(const AuraChatMessage(text: 'Not available', fromAura: true));
      _scrollToBottom();
      return;
    }

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
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final messages = AppStateScope.of(context).auraMessages;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bubble_chart, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Aura AI', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
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
                        onPressed: _sending ? null : () => _send(_quickReplies[index]),
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
                            enabled: !_sending,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              filled: false,
                              hintText: 'Type a message...',
                            ),
                            onSubmitted: _send,
                          ),
                        ),
                        IconButton(
                          onPressed: _sending ? null : () => _send(),
                          icon: Icon(Icons.send, color: scheme.onPrimary),
                          style: IconButton.styleFrom(backgroundColor: scheme.primary),
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
