import 'package:flutter/material.dart';

class _ChatMessage {
  const _ChatMessage(this.text, this.fromAura);
  final String text;
  final bool fromAura;
}

/// Full-screen Aura chat, opened from the floating chat button.
class AuraChatScreen extends StatefulWidget {
  const AuraChatScreen({super.key});

  @override
  State<AuraChatScreen> createState() => _AuraChatScreenState();
}

class _AuraChatScreenState extends State<AuraChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage("Hi there! I'm Aura, your mindful companion. How are you feeling today?", true),
  ];

  static const _quickReplies = ['I need to vent', 'Breathing exercise', 'Just chatting'];

  static const _auraReplies = [
    "I hear you. Thank you for sharing that with me.",
    "That makes a lot of sense. Would it help to write it down in your journal?",
    "Take a slow breath in… and out. You're doing better than you think.",
    "I'm proud of you for checking in today. What's one small thing that could help right now?",
  ];
  int _replyIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(message, false));
      _messages.add(_ChatMessage(_auraReplies[_replyIndex % _auraReplies.length], true));
      _replyIndex++;
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              itemCount: _messages.length,
              itemBuilder: (context, index) => _Bubble(message: _messages[index]),
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
                        onPressed: () => _send(_quickReplies[index]),
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
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              filled: false,
                              hintText: 'Type a message...',
                            ),
                            onSubmitted: _send,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _send(),
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
  final _ChatMessage message;

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
                CircleAvatar(radius: 14, backgroundColor: scheme.primaryContainer, child: Icon(Icons.auto_awesome, size: 14, color: scheme.primary)),
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
