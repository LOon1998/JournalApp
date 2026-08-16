# Moodlet

A Flutter rebuild of the Moodlet mood-journal mockups: daily check-ins, a
free-form journal, a mood calendar, an insights dashboard, an Aura AI
companion chat, and a settings screen — all sharing one Material 3 theme
lifted directly from the mockups' Tailwind color tokens.

## Screens

| Tab / Route        | Source mockup             |
|---------------------|---------------------------|
| Today (bottom nav)  | Daily Check-in            |
| Journal (bottom nav)| Journal Entry             |
| Calendar (bottom nav)| Mood Calendar             |
| Insights (bottom nav)| Insights Dashboard        |
| Settings (gear icon)| Settings                  |
| Aura (bubble icon / FAB) | Aura Chat             |

State (entries, theme mode, toggles) lives in `lib/data/app_state.dart` and
persists locally via `shared_preferences`.

## Run it locally

```bash
flutter pub get
flutter run            # any connected device/emulator
flutter run -d chrome  # web
```

## Live web preview

Every push to this branch builds and deploys `flutter build web` to GitHub
Pages via `.github/workflows/deploy-pages.yml`. Once the **Deploy Flutter
Web to GitHub Pages** workflow run finishes (and GitHub Pages is enabled
once, automatically, by that workflow), the app is live at:

```
https://loon1998.github.io/JournalApp/
```

Scan the QR code shared alongside this project to open it on your phone.

## Project structure

```
lib/
  theme/app_theme.dart      # color tokens + ThemeData (light & dark)
  models/journal_entry.dart # entry data model
  data/app_state.dart       # app-wide ChangeNotifier + persistence
  widgets/                  # shared chrome: top bar, bottom nav, Aura FAB, cards
  screens/                  # one file per screen
```
