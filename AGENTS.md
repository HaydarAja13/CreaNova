# Repository Guidelines

## Project Structure & Module Organization
- Flutter app: `lib/` (features under `lib/pages`, UI in `lib/widgets`, data in `lib/models`, services in `lib/services`).
- Config: `lib/firebase_options.dart`, `lib/app_config.dart`, `analysis_options.yaml`, `pubspec.yaml`.
- Assets: `assets/images`, `assets/icons`, `assets/fonts` (declared in `pubspec.yaml`).
- Tests: `test/` (widget/unit tests, `*_test.dart`).
- Platforms: `android/`, `web/` (PWA assets and splash).
- Cloud Functions: `functions/` (TypeScript Firebase Functions).

## Build, Test, and Development Commands
- Flutter setup: `flutter pub get` (install deps), `flutter analyze` (static checks).
- Run app: `flutter run` (device/emulator), `flutter run -d chrome` (web).
- Build: `flutter build apk` (Android), `flutter build web` (Web release).
- Tests: `flutter test` or `flutter test --coverage`.
- Functions: `cd functions && npm i && npm run lint && npm run build`.
- Emulators: `cd functions && npm run serve` (Functions only). Deploy: `npm run deploy`.

## Coding Style & Naming Conventions
- Lints: `analysis_options.yaml` includes `flutter_lints`. Keep code warning-free.
- Format: `dart format .` (2-space indent, 80–100 cols where practical).
- Naming: files `snake_case.dart`; classes `UpperCamelCase`; methods/vars `lowerCamelCase`.
- Widgets: keep small and composable; put reusable UI in `lib/widgets`.

## Testing Guidelines
- Place tests in `test/` mirroring source paths; name as `something_test.dart`.
- Write widget tests for UI and unit tests for logic/services.
- Run `flutter test` locally before PRs; target meaningful coverage for changed code.

## Commit & Pull Request Guidelines
- Commits: imperative mood, concise subject (≤72 chars), details in body when needed. Example: `Add address form validation`.
- Group related changes; avoid unrelated file churn.
- PRs: include summary, rationale, screenshots/GIFs for UI, steps to test, and linked issues (e.g., `Closes #123`). Ensure CI passes and tests updated.

## Security & Configuration Tips
- Do not commit secrets. `google-services.json` and `firebase_options.dart` are environment-specific; rotate if exposed.
- Node `functions/` uses Node 22; install with an LTS manager and Firebase CLI for local emulation.
