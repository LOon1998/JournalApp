import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted 1:1 from the Lumina web mockups' Tailwind config
/// (the `colors` block shared by every screen).
abstract class LuminaColors {
  // Light ("light" html class) tokens.
  static const lightPrimary = Color(0xFF366758);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFB5EAD7);
  static const lightOnPrimaryContainer = Color(0xFF396B5C);
  static const lightPrimaryFixed = Color(0xFFB9EEDB);
  static const lightPrimaryFixedDim = Color(0xFF9DD1BF);
  static const lightOnPrimaryFixed = Color(0xFF002018);
  static const lightOnPrimaryFixedVariant = Color(0xFF1C4F41);
  static const lightInversePrimary = Color(0xFF9DD1BF);

  static const lightSecondary = Color(0xFF745945);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFFDD9C0);
  static const lightOnSecondaryContainer = Color(0xFF785D49);
  static const lightSecondaryFixed = Color(0xFFFFDCC4);
  static const lightSecondaryFixedDim = Color(0xFFE3C0A8);
  static const lightOnSecondaryFixed = Color(0xFF2A1708);
  static const lightOnSecondaryFixedVariant = Color(0xFF5A422F);

  static const lightTertiary = Color(0xFF566246);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFD6E4C0);
  static const lightOnTertiaryContainer = Color(0xFF5A6649);
  static const lightTertiaryFixed = Color(0xFFDAE8C3);
  static const lightTertiaryFixedDim = Color(0xFFBECBA8);
  static const lightOnTertiaryFixed = Color(0xFF141F08);
  static const lightOnTertiaryFixedVariant = Color(0xFF3F4B30);

  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF93000A);

  static const lightBackground = Color(0xFFF7F9FC);
  static const lightOnBackground = Color(0xFF191C1E);
  static const lightSurface = Color(0xFFF7F9FC);
  static const lightOnSurface = Color(0xFF191C1E);
  static const lightSurfaceVariant = Color(0xFFE0E3E6);
  static const lightOnSurfaceVariant = Color(0xFF404945);
  static const lightSurfaceBright = Color(0xFFF7F9FC);
  static const lightSurfaceDim = Color(0xFFD8DADD);

  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow = Color(0xFFF2F4F7);
  static const lightSurfaceContainer = Color(0xFFECEEF1);
  static const lightSurfaceContainerHigh = Color(0xFFE6E8EB);
  static const lightSurfaceContainerHighest = Color(0xFFE0E3E6);

  static const lightOutline = Color(0xFF707975);
  static const lightOutlineVariant = Color(0xFFC0C9C4);
  static const lightInverseSurface = Color(0xFF2D3133);
  static const lightInverseOnSurface = Color(0xFFEFF1F4);
  static const lightSurfaceTint = Color(0xFF366758);

  /// Mood accent used by "sunset" journal theme swatch.
  static const sunset = Color(0xFFF7C59F);
}

/// Writing Theme swatches offered in Journal's composer, keyed by the name
/// stored in [JournalEntry.themeName] — shared (rather than living
/// privately in journal_screen.dart) so the entry detail screen can look
/// up the same color to keep a saved entry's cards tinted the way it was
/// written in.
const journalThemes = <String, Color>{
  'Sunset': Color(0xFFFBD6B0),
  'Sage': Color(0xFFD6E4C0),
  'Sky': Color(0xFFBFDBFE),
  'Yellow': Color(0xFFFDE68A),
  'White': Colors.white,
};

/// Pre-selected when the composer opens (and again after each Complete
/// Entry) rather than leaving Writing Theme unset by default.
const defaultJournalTheme = 'Yellow';

/// The actual color a Writing Theme swatch renders/tints with — [White]
/// is meant to read as "neutral, no real tint", which only holds in
/// light mode: blending white *into* a light surface leaves it looking
/// unchanged, but blending white into a dark surface visibly lightens it
/// toward grey, breaking dark mode's own look. Resolving it to black in
/// dark mode keeps the same "blends in, no visible tint" behavior on
/// both, since black blended into an already-near-black surface stays
/// near-black. Every other swatch is a fixed color regardless of theme.
Color resolveJournalThemeColor(String themeName, Brightness brightness) {
  if (themeName == 'White' && brightness == Brightness.dark) return Colors.black;
  return journalThemes[themeName] ?? journalThemes[defaultJournalTheme]!;
}

/// Semantic mood palette, shared by the check-in picker, calendar dots,
/// journal entry badges and the insights "most frequent" card.
enum Mood {
  great('Great', '🤩', Color(0xFFF9A8D4), Color(0xFF701A44)),
  good('Good', '😎', Color(0xFFBBF7D0), Color(0xFF14532D)),
  okay('Okay', '😐', Color(0xFFFED7AA), Color(0xFF7C2D12)),
  sad('Sad', '😢', Color(0xFFBFDBFE), Color(0xFF1E3A8A)),
  // Grey rather than red/pink — a "bad mood" indicator doesn't need to
  // read as an alarm color.
  awful('Awful', '😩', Color(0xFFE5E7EB), Color(0xFF374151));

  const Mood(this.label, this.emoji, this.swatch, this.onSwatch);

  final String label;
  final String emoji;
  final Color swatch;
  final Color onSwatch;
}

class AppTheme {
  static ColorScheme get _lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: LuminaColors.lightPrimary,
        onPrimary: LuminaColors.lightOnPrimary,
        primaryContainer: LuminaColors.lightPrimaryContainer,
        onPrimaryContainer: LuminaColors.lightOnPrimaryContainer,
        secondary: LuminaColors.lightSecondary,
        onSecondary: LuminaColors.lightOnSecondary,
        secondaryContainer: LuminaColors.lightSecondaryContainer,
        onSecondaryContainer: LuminaColors.lightOnSecondaryContainer,
        tertiary: LuminaColors.lightTertiary,
        onTertiary: LuminaColors.lightOnTertiary,
        tertiaryContainer: LuminaColors.lightTertiaryContainer,
        onTertiaryContainer: LuminaColors.lightOnTertiaryContainer,
        error: LuminaColors.lightError,
        onError: LuminaColors.lightOnError,
        errorContainer: LuminaColors.lightErrorContainer,
        onErrorContainer: LuminaColors.lightOnErrorContainer,
        surface: LuminaColors.lightSurface,
        onSurface: LuminaColors.lightOnSurface,
        surfaceContainerLowest: LuminaColors.lightSurfaceContainerLowest,
        surfaceContainerLow: LuminaColors.lightSurfaceContainerLow,
        surfaceContainer: LuminaColors.lightSurfaceContainer,
        surfaceContainerHigh: LuminaColors.lightSurfaceContainerHigh,
        surfaceContainerHighest: LuminaColors.lightSurfaceContainerHighest,
        onSurfaceVariant: LuminaColors.lightOnSurfaceVariant,
        outline: LuminaColors.lightOutline,
        outlineVariant: LuminaColors.lightOutlineVariant,
        inverseSurface: LuminaColors.lightInverseSurface,
        onInverseSurface: LuminaColors.lightInverseOnSurface,
        inversePrimary: LuminaColors.lightInversePrimary,
        surfaceTint: LuminaColors.lightSurfaceTint,
      );

  // Dark scheme: tonal-inverted, keeping the same hue family so the app
  // still reads as "Lumina" when the Settings > Appearance toggle is Dark.
  static ColorScheme get _darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF9DD1BF),
        onPrimary: Color(0xFF073829),
        primaryContainer: Color(0xFF1C4F41),
        onPrimaryContainer: Color(0xFFB9EEDB),
        secondary: Color(0xFFE3C0A8),
        onSecondary: Color(0xFF3F2B1A),
        secondaryContainer: Color(0xFF5A422F),
        onSecondaryContainer: Color(0xFFFFDCC4),
        tertiary: Color(0xFFBECBA8),
        onTertiary: Color(0xFF2A331B),
        tertiaryContainer: Color(0xFF3F4B30),
        onTertiaryContainer: Color(0xFFDAE8C3),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF101412),
        onSurface: Color(0xFFE0E3E0),
        surfaceContainerLowest: Color(0xFF0B0F0D),
        surfaceContainerLow: Color(0xFF181D1A),
        surfaceContainer: Color(0xFF1C211E),
        surfaceContainerHigh: Color(0xFF262B28),
        surfaceContainerHighest: Color(0xFF313633),
        onSurfaceVariant: Color(0xFFC0C9C4),
        outline: Color(0xFF8A938E),
        outlineVariant: Color(0xFF404945),
        inverseSurface: Color(0xFFE0E3E0),
        onInverseSurface: Color(0xFF191C1E),
        inversePrimary: Color(0xFF366758),
        surfaceTint: Color(0xFF9DD1BF),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = GoogleFonts.quicksandTextTheme(base.textTheme);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      splashFactory: InkRipple.splashFactory,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 2),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);
}

extension MoodStyle on Mood {
  /// Filled Material Symbol shown on entry cards/badges for this mood.
  IconData get icon {
    switch (this) {
      case Mood.great:
        return Icons.sentiment_very_satisfied;
      case Mood.good:
        return Icons.sentiment_satisfied;
      case Mood.okay:
        return Icons.sentiment_neutral;
      case Mood.sad:
        return Icons.sentiment_dissatisfied;
      case Mood.awful:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}
