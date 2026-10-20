# Verification report

Environment on 2026-10-20: Windows 11, Flutter 3.47.7 stable, Dart 3.13.5, Android Studio bundled OpenJDK 25.0.3, Android SDK 37.0.0. Flutter is installed at `C:\src\flutter`, not on the default PATH. The original workspace does not contain Git metadata.

## Flutter client

- `flutter pub get` — passed after adding `supabase_flutter 2.18.3`; lockfile updated.
- Earlier `flutter analyze` passed and `flutter test --coverage` passed 20 tests before the three AI tutor widget tests were added. Earlier web/APK builds passed before the latest AI changes.
- Current `dart format lib test` — passed; 23 Dart files inspected and 4 formatted.
- Current standalone `dart analyze lib test` — passed with no issues.
- Current `flutter test --coverage`, `flutter analyze`, and web/APK rebuilds could not run: an existing Dart process holds `C:\src\flutter\bin\cache\lockfile`. The current Flutter suite contains 23 tests, but the three AI widget tests have not been executed. No existing IDE/Dart process was stopped.
- The earlier 52.2 MB release-mode APK uses the template debug signing key and is not suitable for Play Store submission.
- Earlier `flutter run -d chrome` — launched without an observed runtime error before the account integration. The latest web production build compiles successfully; a connected hosted Supabase flow has not been launched because no project credentials exist.

No Android emulator/device was connected for APK installation/runtime checks. The iOS host exists and now has a custom authentication URL scheme, but this Windows machine lacks macOS/Xcode, so iOS builds/signing/simulator checks could not run. Flutter Doctor's Visual Studio C++ workload warning applies to Windows desktop only.

## Supabase backend source (not yet executed)

Created a SQL migration, sample A1–C2 learning pathways (all marked sample), RLS for profiles/progress/curriculum/teacher applications/notifications, a private teacher-verification Storage bucket, account/quota pgTAP tests, and an AI tutor Edge Function with an OpenAI Responses API adapter and Deno tests.

`supabase test db` was **not run**: Supabase CLI and Docker are unavailable, and no project/credentials were supplied. Deno is also unavailable, so Edge Function type-checks/tests were not run. The migration has not been applied to a database and the function is not deployed. RLS, auth emails, password reset, cloud sync, AI request handling, and usage settlement are not claimed verified. Dart tests use fakes and do not substitute for live Postgres/provider checks.

## Original browser prototype

`powershell -NoProfile -ExecutionPolicy Bypass -File tests/smoke.ps1` — all 23 assertions passed again, including local progress migration and 390px/320px overflow checks. The original `index.html`, `styles.css`, `app.js`, smoke test, and browser workflow were preserved.

## Not implemented / not claimed

The AI tutor client, Edge Function, provider adapter, quota/cost logic, and test sources are implemented but not run or deployed. No voice provider, video platform, full reviewed/authorized curriculum, teacher marketplace or booking transactions, payment integration, admin product, production signing, deployed hosting, or app-store release. No Git repository exists in the workspace.
