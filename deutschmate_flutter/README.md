# DeutschMate AI — Flutter client

Flutter/Dart client with generated Android, iOS, and web projects. The original HTML/CSS/JavaScript reference remains at the repository root.

## Implemented

Arabic RTL and German/English LTR; responsive Material 3 shell; A1 sample learning flow, vocabulary review and quiz; device-local guest state; optional Supabase Auth and per-account progress repository; email/password signup/sign-in, verification status, password reset/change, and sign-out. Account rows are intended to be isolated by the PostgreSQL RLS migration. Guest data is not silently copied into an account.

The Supabase migration also defines profiles, sample A1–C2 pathway outlines, teacher applications, notification/AI metering/audit tables, and private teacher document storage. All lesson seeds are sample content, not official or reviewed course material.

## Verification

On Flutter 3.47.7/Dart 3.13.5, formatting/analyzer passed, all 20 Flutter tests passed, `flutter build web` passed, and `flutter build apk --release` passed (52.2 MB, signed with debug key). The original browser test passed 23 checks. See parent `TEST_REPORT.md`.

No Supabase project/credentials, Supabase CLI, or Docker are available. The SQL migration and RLS tests have not run; no cloud service is connected. iOS requires macOS/Xcode and has not been built.

## Connect Supabase

Follow parent [`SUPABASE_SETUP.md`](../SUPABASE_SETUP.md). Copy `supabase.config.example.json` to the ignored `supabase.config.json`, insert only the project URL and publishable key, then use `--dart-define-from-file=supabase.config.json`. Never put a service-role/AI/payment key in a client build.

```powershell
flutter pub get
dart format .
flutter analyze
flutter test --coverage
flutter run --dart-define-from-file=supabase.config.json
flutter build web --dart-define-from-file=supabase.config.json
flutter build apk --release --dart-define-from-file=supabase.config.json
```

The Android release signing key is still the generated debug key. Configure production signing and verify on devices before distribution.
