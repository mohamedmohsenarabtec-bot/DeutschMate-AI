# DeutschMate AI implementation status

## Verified client and account foundation

- [x] Preserved the root HTML/CSS/JavaScript prototype, smoke test, and browser workflow.
- [x] Flutter/Dart client for Android, iOS, and web host projects; Arabic RTL and German/English LTR.
- [x] A1 sample lesson, vocabulary review, grammar quiz, local guest progress, settings/theme.
- [x] Added `supabase_flutter`, optional client initialization through build-time URL/publishable-key defines, email/password account UI, email-confirmation state, password reset/change, and sign-out.
- [x] Account-scoped progress adapter; no silent migration/merging of guest progress; stale account-load results are discarded.
- [x] Added PostgreSQL migration source for profiles, course pathways, progress, teacher applications, notifications, AI metering, audit records, RLS, and private teacher-document storage; added labeled A1–C2 sample pathway seeds and pgTAP cross-user tests.
- [x] Formatting and analyzer pass; 20 Flutter tests passed before adding the AI tutor widget tests; web and Android release-mode builds passed before the latest AI changes; original browser smoke test passes 23 checks.
- [x] AI tutor client, authenticated Supabase Edge Function, OpenAI Responses API adapter, actual token-cost settlement, request limits, owner-scoped conversations, and Deno/pgTAP test sources are implemented.
- [ ] Re-run 23 Flutter tests and rebuild web/APK after the AI changes; SDK lock was held by an existing Dart process during latest verification. Run Deno and pgTAP tests after installing the unavailable tools.

## Current backend and launch state

Supabase CLI/Docker/Deno and project credentials are absent. SQL migration, pgTAP, and Deno test sources are not applied or executed; no Edge Function is deployed. Live email verification, password recovery, cloud sync, RLS enforcement, AI behavior, usage accounting, and production auth configuration are therefore not verified. Follow `SUPABASE_SETUP.md` before connecting a project. Android APK uses debug signing; iOS cannot be built on this Windows machine; nothing is deployed or published.

## Remaining independently testable product milestones

1. Apply Supabase schema, run pgTAP and client integration tests; verify owner isolation with two real local Auth users.
2. Complete account profile management and guest-progress import consent; account deletion/export and privacy retention.
3. Provision a development Supabase project, configure current OpenAI model pricing/secrets server-side, run Deno/pgTAP tests, deploy the AI Edge Function, and validate it with authenticated test accounts.
4. Expand the sample pathway outlines into linguistically reviewed/licensed A1–C2 lesson, assessment, exam-practice, worksheet, audio, and speaking content. Do not claim official exam results.
5. Add actual playback/speech/worksheet generation only with tested providers and graceful offline behavior.
6. Implement teacher approval/profile/availability and transactional, conflict-safe booking, cancellation, reminders, disputes, reviews, and commission ledger.
7. Confirm payment eligibility/provider and app-store rules; implement test-mode checkout/receipt verification, idempotent callbacks, refunds, entitlements, and reconciliation.
8. Build role-protected admin/support portal and audit flows.
9. Perform Android device and iOS/macOS test/signing, accessibility/device QA, production deployment, monitoring, backup restore, and store submission.

## Architecture

Flutter/Dart is the client foundation across platforms; the original HTML site remains the reference implementation. Supabase/PostgreSQL is selected as backend, not yet provisioned. Public discoverability pages may need a separate server-rendered/SEO component based on final requirements.
