# DeutschMate AI

DeutschMate preserves the original Arabic-first HTML/CSS/JavaScript browser prototype at the repository root and contains a separate Flutter/Dart client in [`deutschmate_flutter`](deutschmate_flutter/README.md). The Flutter client has optional Supabase email authentication, account-scoped progress persistence, and an AI tutor interface wired to a server-side Supabase Edge Function. The local prototype remains unchanged and its original browser checks are still passing.

## Current verification (2026-10-20)

Environment: Windows 11, Flutter 3.47.7, Dart 3.13.5, Android Studio bundled OpenJDK 25.0.3, Android SDK 37.0.0.

- Earlier validation passed formatting, analysis, 20 Flutter tests, web/APK builds, and all 23 prototype smoke checks. The APK is debug-signed.
- After the AI slice, Dart's standalone analyzer passes with no issues; prototype smoke checks again pass all 23 assertions.
- The current 23 Flutter tests, web/APK rebuilds, Deno tests, and SQL pgTAP tests have not been run. Flutter is blocked by an existing Dart process holding the SDK lock; Deno/Supabase CLI/Docker and backend credentials are unavailable.

See [TEST_REPORT.md](TEST_REPORT.md). Backend SQL tests and live Supabase requests are not yet verified: Supabase CLI/Docker and project credentials are not available. Follow [SUPABASE_SETUP.md](SUPABASE_SETUP.md) to configure and test them.

## Product status

Implemented client features include Arabic RTL/German and English LTR, adaptive navigation, the A1 sample lesson, vocabulary review, grammar quiz, local guest progress, account creation/sign-in/out, email verification, password reset/change, account-scoped progress code, and AI chat UI with CEFR/task selection. Guest and account data are deliberately separate; there is no automatic guest-to-cloud merge.

The SQL schema, RLS policies, sample pathways, private teacher-document bucket, and account/quota pgTAP tests are present under `deutschmate_flutter/supabase`. The AI Edge Function uses session validation, server-only secrets, cost-aware quotas, and the OpenAI Responses API. Neither database nor Edge Function has been deployed or tested against a live project. No Supabase project is connected, so cloud auth/sync/AI remain unverified and the app runs in device-local guest mode by default.

Voice/video service, reviewed full curriculum, teacher booking workflow, payments, admin console, production signing, deployment, and store publication remain unimplemented. See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) and [SUPABASE_SETUP.md](SUPABASE_SETUP.md).
