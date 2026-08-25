import 'dart:convert';
import 'package:http/http.dart' as http;

/// Distinguishes *why* a Gemini call failed, for callers that need to react
/// differently to specific cases — currently just [dailyLimitReached] (see
/// AuraChatScreen, which dims its composer for the rest of the session on
/// that one specifically, since retrying is guaranteed to fail again until
/// tomorrow, unlike every other reason here).
enum GeminiFailureReason { network, badRequest, dailyLimitReached, rateLimited, serverError, badResponse }

/// Thrown for any Gemini call failure, with a message already safe to show
/// directly in the UI (no raw exception text / stack traces).
class GeminiException implements Exception {
  const GeminiException(this.message, [this.reason = GeminiFailureReason.serverError]);
  final String message;
  final GeminiFailureReason reason;

  @override
  String toString() => message;
}

// The "-latest" alias always resolves to Google's current stable Flash
// model, instead of pinning to a specific dated version that can 404 once
// it's retired or isn't available for a given key/region.
const _model = 'gemini-flash-latest';

/// Baked in at *build* time via `--dart-define=GEMINI_API_KEY=...` (see
/// .github/workflows/deploy-pages.yml, which reads it from an encrypted
/// GitHub Actions secret) — never committed to source, so it's kept out
/// of the repo's own git history, unlike a key typed directly into a
/// file. It still ends up compiled into the shipped JS like any
/// client-side key, so this isn't a way to fully hide it from the
/// deployed site's own visitors — just from the repo itself.
const _buildTimeApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// The key actually used for a call: whatever's saved in Settings takes
/// priority (so testing locally with your own key always wins), falling
/// back to the build-time one so the deployed app works with zero setup.
/// Null if neither is set.
String? resolveGeminiApiKey(String? userKey) {
  if (userKey != null && userKey.isNotEmpty) return userKey;
  return _buildTimeApiKey.isEmpty ? null : _buildTimeApiKey;
}

/// Sends [prompt] to Gemini and returns its raw text reply — a
/// single-turn convenience wrapper around [_generateFromContents] for the
/// (most common) case of just asking one question with no conversation
/// history to carry.
Future<String> _generateText(String apiKey, String prompt, {double temperature = 0.2}) => _generateFromContents(apiKey, [
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      },
    ], temperature: temperature);

/// [GeminiFailureReason]s worth automatically retrying on — a dropped
/// connection, a per-minute rate limit, or a momentary server-side hiccup
/// can all plausibly succeed a moment later with the exact same request.
/// [badRequest] (a genuinely rejected key) and [dailyLimitReached] (won't
/// recover until tomorrow) never will, so those still surface to the
/// caller immediately instead of silently retrying something guaranteed
/// to fail the same way again. [badResponse] is left out too — a
/// malformed reply is more likely a real parsing mismatch than a fluke,
/// so retrying it silently would just mask a bug instead of fixing one.
const _retryableFailureReasons = {
  GeminiFailureReason.network,
  GeminiFailureReason.rateLimited,
  GeminiFailureReason.serverError,
};

/// Same as [_generateFromContentsOnce], but automatically retries (with a
/// short backoff) on any of [_retryableFailureReasons] before giving up
/// and surfacing the failure to the caller. This is what turns a
/// momentary network blip or rate-limit brush into something that just
/// quietly resolves on its own a moment later, instead of an error the
/// person has to notice and manually retry themselves — the exact
/// "sometimes works, sometimes doesn't" flakiness that used to reach the
/// UI as a visible failure even when a second attempt, seconds later,
/// would have gone through fine.
Future<String> _generateFromContents(
  String apiKey,
  List<Map<String, dynamic>> contents, {
  double temperature = 0.2,
  String? systemInstruction,
}) async {
  const retryDelays = [Duration(seconds: 1), Duration(seconds: 2)];
  for (var attempt = 0; ; attempt++) {
    try {
      return await _generateFromContentsOnce(apiKey, contents, temperature: temperature, systemInstruction: systemInstruction);
    } on GeminiException catch (e) {
      if (!_retryableFailureReasons.contains(e.reason) || attempt >= retryDelays.length) rethrow;
      await Future.delayed(retryDelays[attempt]);
    }
  }
}

/// Sends a full multi-turn [contents] array (each entry `{role: "user"|
/// "model", parts: [{text: ...}]}`) to Gemini and returns its raw text
/// reply, with any ```-fenced wrapping stripped. Shared by every function
/// in this file — handles the HTTP call, network/timeout failures, and
/// non-200 responses; callers are only responsible for building their own
/// contents and parsing the returned text into whatever shape they need.
/// [systemInstruction], when given, sets persistent behavior/persona
/// instructions separately from the actual conversation turns.
Future<String> _generateFromContentsOnce(
  String apiKey,
  List<Map<String, dynamic>> contents, {
  double temperature = 0.2,
  String? systemInstruction,
}) async {
  final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey');

  http.Response response;
  try {
    response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (systemInstruction != null)
              'systemInstruction': {
                'parts': [
                  {'text': systemInstruction},
                ],
              },
            'contents': contents,
            'generationConfig': {'temperature': temperature},
          }),
        )
        .timeout(const Duration(seconds: 30));
  } catch (_) {
    throw const GeminiException(
        'Could not reach Gemini — check your connection and try again.', GeminiFailureReason.network);
  }

  if (response.statusCode == 400 || response.statusCode == 403) {
    throw const GeminiException(
        'Gemini rejected the request — double-check your API key in Settings.', GeminiFailureReason.badRequest);
  }
  // 429 = rate limit / quota hit (the free tier's own request-per-minute
  // or request-per-day cap, shared by everyone using this app's key).
  // Gemini's error body names which specific quota metric was exceeded —
  // a per-day one won't recover for hours, so that gets its own message
  // (and its own [GeminiFailureReason], for callers like AuraChatScreen
  // that dim their UI on this one specifically) instead of implying "try
  // again in a few minutes" when it won't help.
  if (response.statusCode == 429) {
    final isDailyLimit = response.body.toLowerCase().contains('perday');
    throw GeminiException(
        isDailyLimit
            ? "Not available — today's usage limit has been reached. Try again tomorrow."
            : "Aura's a little busy right now — try again in a few minutes.",
        isDailyLimit ? GeminiFailureReason.dailyLimitReached : GeminiFailureReason.rateLimited);
  }
  if (response.statusCode != 200) {
    // No raw status code shown here on purpose — it's not actionable for
    // the person reading it, just noise.
    throw const GeminiException('Not available right now. Try again in a moment.');
  }

  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List<dynamic>?;
    final parts = ((candidates?.first as Map<String, dynamic>?)?['content'] as Map<String, dynamic>?)?['parts']
        as List<dynamic>?;
    var raw = (parts?.first as Map<String, dynamic>?)?['text'] as String? ?? '';
    // Gemini sometimes wraps its reply in ```json ... ``` fences despite
    // being asked not to — strip those before the caller tries to decode it.
    raw = raw.trim();
    if (raw.startsWith('```')) {
      raw = raw.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
    }
    if (raw.isEmpty) {
      throw const GeminiException("Gemini didn't return anything usable. Try again in a moment.",
          GeminiFailureReason.badResponse);
    }
    return raw;
  } on GeminiException {
    rethrow;
  } catch (_) {
    throw const GeminiException(
        "Couldn't read Gemini's response. Try again in a moment.", GeminiFailureReason.badResponse);
  }
}

/// Minimal round-trip to confirm [apiKey] actually authenticates — used by
/// Settings' connection-status check. Throws [GeminiException] (with a
/// UI-safe message) on any failure; returns normally on success.
Future<void> testGeminiConnection(String apiKey) => _generateText(apiKey, 'Reply with just the word "OK".');

/// Picks the best-fitting icon for each of [activities] from the fixed
/// [validIconKeys] vocabulary (Gemini can only ever return an IconData by
/// name lookup, not invent one, so it's constrained to choosing among
/// keys the caller already has real icons for). Activities Gemini can't
/// find a good match for are simply omitted from the result — callers
/// should treat a missing key as "no icon" rather than an error.
Future<Map<String, String>> fetchActivityIcons(
  String apiKey,
  List<String> activities,
  List<String> validIconKeys,
) async {
  if (activities.isEmpty) return {};
  final prompt = '''
Below is a list of personal journal tags/activities. For each one, pick the single best-matching icon key from this fixed vocabulary — you must only use keys from this list, never invent your own: ${validIconKeys.join(', ')}.

If none of the vocabulary keys are a reasonable fit for a given activity, omit that activity from your answer entirely rather than guessing.

Respond with ONLY a JSON object mapping each activity (exactly as written below) to its chosen icon key, no other text, no markdown fences, in this exact shape:
{"Exercise": "exercise", "Work": "work"}

Activities:
${activities.join(', ')}
''';

  final raw = await _generateText(apiKey, prompt);
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in map.entries)
        if (entry.value is String && validIconKeys.contains(entry.value)) entry.key: entry.value as String,
    };
  } on GeminiException {
    rethrow;
  } catch (_) {
    throw const GeminiException("Couldn't read Gemini's response. Try again in a moment.");
  }
}

/// One turn of the Aura chat — [fromAura] false means the user sent it.
class AuraTurn {
  const AuraTurn({required this.text, required this.fromAura});
  final String text;
  final bool fromAura;
}

// Aura's persona. Kept short/conversational on purpose — this is a mobile
// chat-bubble UI, not an essay generator — and explicitly told to defer
// to a real person rather than try to handle real crisis/distress itself,
// since this sits inside a mental-wellness-adjacent journaling app.
// [languageCode] is the app's current UI language ('en'/'zh') — without
// telling Gemini which one, replies came back in English regardless of
// what language the rest of the app (and the person typing to it) was
// actually in.
String _auraSystemInstruction(String languageCode) {
  final language = switch (languageCode) {
    'zh' => 'Simplified Chinese',
    _ => 'English',
  };
  return '''
You are Aura, a warm and caring daily companion inside a personal journaling app. You check in on the user like a supportive friend would — casual, encouraging, and genuinely curious about their day. You are not a therapist and never sound clinical, robotic, or like you're reading from a script.

Guidelines:
- Reply in $language, regardless of what language the app's own interface elsewhere is showing.
- Keep replies short: 1-3 sentences, like a real text conversation, not an essay.
- Match the user's tone — playful if they're playful, gentle if they're down.
- Ask a simple, genuine follow-up question when it fits naturally, to keep the conversation going, but don't force one into every single reply.
- Never diagnose, lecture, or moralize.
- If the user expresses serious distress, self-harm, or crisis, gently and briefly encourage them to reach out to a real person, a trusted contact, or a crisis line — don't try to handle it yourself, and don't dwell on it unless they keep bringing it up.
- You only know what's been said in this conversation — you have no memory of past sessions.
''';
}

/// Sends the whole conversation so far (oldest first) plus [userMessage]
/// to Gemini, replying in character as Aura, in [languageCode]. Throws
/// [GeminiException] (UI-safe message) on any failure — callers should
/// show that inline in the chat rather than crash the conversation.
Future<String> sendAuraMessage(String apiKey, List<AuraTurn> history, String userMessage, String languageCode) {
  final contents = [
    for (final turn in history)
      {
        'role': turn.fromAura ? 'model' : 'user',
        'parts': [
          {'text': turn.text},
        ],
      },
    {
      'role': 'user',
      'parts': [
        {'text': userMessage},
      ],
    },
  ];
  return _generateFromContents(apiKey, contents,
      temperature: 0.8, systemInstruction: _auraSystemInstruction(languageCode));
}

/// Writes a fresh Journal "Daily Reflection" prompt — one short, open-
/// ended question meant to nudge someone into writing, in the same style
/// as "What's one small thing that made you smile today?". High
/// temperature on purpose so repeated calls (different days) don't
/// converge on the same handful of phrasings. [languageCode] is the
/// app's current UI language ('en'/'zh', from Settings' language picker
/// or the device default) — without explicitly asking Gemini to reply in
/// it, prompts came back in English regardless of the app's own
/// language, which read as a jarring mismatch on a Chinese-language
/// screen.
Future<String> fetchDailyReflectionPrompt(String apiKey, String languageCode) async {
  final language = switch (languageCode) {
    'zh' => 'Simplified Chinese',
    _ => 'English',
  };
  final prompt = '''
Write exactly one short, warm, open-ended journaling prompt for a personal journal app's "Daily Reflection" feature — the kind of single gentle question that nudges someone to write a few sentences about their day. Match this style and length exactly:

"What's one small thing that made you smile today?"
"What's something you're looking forward to?"
"Is there a moment today you'd like to remember?"

Write it in $language.

Respond with ONLY the prompt itself, as a single sentence ending in a question mark — no quotation marks, no preamble, no markdown, nothing else.
''';
  final raw = await _generateText(apiKey, prompt, temperature: 0.9);
  final cleaned = raw.replaceAll('"', '').trim();
  if (cleaned.isEmpty) {
    throw const GeminiException("Gemini didn't return anything usable. Try again in a moment.");
  }
  return cleaned;
}

