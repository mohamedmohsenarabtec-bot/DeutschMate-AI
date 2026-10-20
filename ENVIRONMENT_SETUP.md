# Environment setup and verified commands

## Local environment (2026-10-20)

- Windows 11; Flutter 3.47.7 at `C:\src\flutter`; Dart 3.13.5. Flutter is not on default PATH.
- Android Studio bundled OpenJDK 25.0.3, Android SDK 37.0.0, NDK 28.2.13676358, Chrome.
- Android and web toolchains passed Flutter Doctor. iOS needs macOS/Xcode. Visual Studio C++ workload is absent (needed only for Windows desktop builds).
- Supabase CLI, Docker, psql, Node/npm, remote database, and service credentials are unavailable. No Git repository exists.

## Flutter commands

From `deutschmate_flutter`, after adding Flutter's bin directory to PATH:

```powershell
flutter pub get
dart format .
flutter analyze
flutter test --coverage
flutter build web
flutter build apk --release
```

All commands above were run successfully for the current source (test count 20). The APK release build signs with the generated debug key; configure protected production signing before distribution.

## Supabase

See [SUPABASE_SETUP.md](SUPABASE_SETUP.md) for exact CLI, migration, seed, pgTAP, auth redirect, and client configuration steps. A project URL and publishable key are client-side values; no privileged secret belongs in Flutter. Without defines, the app remains in clearly labeled local guest mode.
