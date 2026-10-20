# Supabase setup and verification

## What is already in the workspace

- `supabase/migrations/20261020000100_core_learning_and_accounts.sql`: profiles, server-owned roles, course pathway tables, account-scoped learner state, teacher applications, notification/AI metering/audit records, RLS policies, profile creation trigger, and a private teacher verification bucket with owner-path restrictions.
- `supabase/seed.sql`: Arabic/German/English A1–C2 learning pathways and sample lesson outlines. Every seeded item is labeled `sample`; none is represented as reviewed, licensed, official Goethe content, or a complete CEFR course.
- `supabase/tests/database/accounts_and_progress_rls.test.sql`: two-user pgTAP isolation and role-escalation tests.
- `supabase/tests/database/ai_quota_and_cost.test.sql`: quota, reservation, settlement, and cost-ledger tests.
- `deutschmate_flutter/supabase/functions/ai-tutor`: authenticated AI tutor Edge Function, OpenAI Responses API adapter, quota accounting, and Deno unit tests.
- `supabase/config.toml`: local Supabase setup with email confirmations enabled.
- `lib/features/account`: email/password sign-up and sign-in, email-verification notice, password reset/change flow, and sign-out.
- `SupabaseCloudLearningStore`: reads/writes the current user's row in `student_progress` and updates only that user's profile through user-scoped PostgREST requests. PostgreSQL RLS remains the server authorization layer.

The app uses local guest storage when URL/key defines are absent. Guest progress is not copied to an account automatically. Account sync code is implemented but is **not connected or live-verified** until a Supabase project is supplied and the migration/tests run.

The AI chat client and server function are implemented, but are **not live** until the database migration, Deno tests, Edge Function deployment, and secrets are configured. The function authenticates a Supabase session, reserves per-user/project quota, calls OpenAI with a server-only key, and records actual token usage. Provider response storage is disabled. It is text chat only; voice, video, and teacher services are not included.

## Create and validate a local backend

Install the official Supabase CLI and Docker Desktop (or another Docker-compatible runtime). They were not installed on the inspected machine. From `deutschmate_flutter`:

```powershell
supabase start
supabase db reset
supabase test db
```

`supabase db reset` recreates the local database, runs migrations, and applies the seed. Use only for local development; it deletes the local database contents. `supabase test db` runs the pgTAP tests. Do not push the unreviewed sample curriculum directly to a production database.

For a hosted project, create a separate development project and apply migrations using reviewed Supabase CLI workflows. Confirm that migrations apply cleanly and the RLS tests pass before pointing any client at it. No project has been created, linked, or migrated by this work.

## Connect Flutter with client-safe values

From the Supabase project Connect panel, copy its Project URL and **publishable** key. The publishable key is intended for a client and is safe only alongside correct RLS. Never use `service_role`, a database password, provider secret, or payment secret in Flutter.

1. Copy `supabase.config.example.json` to `supabase.config.json`.
2. Replace the two placeholders with the project URL and publishable key.
3. `supabase.config.json` is gitignored. Do not commit it.
4. Run from `deutschmate_flutter`:

```powershell
flutter run --dart-define-from-file=supabase.config.json
flutter test --coverage
flutter build web --dart-define-from-file=supabase.config.json
flutter build apk --release --dart-define-from-file=supabase.config.json
```

`.env.example` documents the same client-safe values but is not automatically loaded by Flutter; the ignored JSON file is consumed through `--dart-define-from-file`. A URL or key alone is not enough to secure a project: apply the migration and verify tests first.

## Configure and deploy the AI tutor

Install Deno and the Supabase CLI, then run the Edge Function unit tests and type checks from `deutschmate_flutter`:

```powershell
deno task --config supabase/functions/deno.json check
deno task --config supabase/functions/deno.json test
```

Deploy only after the database migration and SQL tests pass. Keep all secrets server-side. Configure `SUPABASE_URL`, `SUPABASE_ANON_KEY` (the client key used to validate user sessions), `SUPABASE_SERVICE_ROLE_KEY`, `OPENAI_API_KEY`, and `OPENAI_MODEL` as Edge Function secrets. Also set `AI_INPUT_MICROUSD_PER_MILLION` and `AI_OUTPUT_MICROUSD_PER_MILLION` to the selected model's current published token prices in micro-USD per million tokens. Confirm current prices with the provider before deployment; this project does not prescribe a model or price. Optional controls include `AI_USER_DAILY_BUDGET_MICROUSD`, `AI_PROJECT_DAILY_BUDGET_MICROUSD`, `AI_DAILY_REQUEST_LIMIT`, `AI_PER_MINUTE_REQUEST_LIMIT`, `AI_MAX_INPUT_TOKENS`, `AI_MAX_OUTPUT_TOKENS`, and comma-separated exact web origins in `AI_ALLOWED_ORIGINS`.

Link only the intended development project, set secrets with the Supabase CLI or a secure secret manager, and deploy `ai-tutor` with JWT verification enabled (`verify_jwt = true` in project config). Never put `OPENAI_API_KEY` or `SUPABASE_SERVICE_ROLE_KEY` in Flutter defines, a web bundle, `.env.example`, or source control. Validate quota exhaustion, failure recovery, conversation ownership, and usage in a non-production project before launch. These steps have not run here; Deno, Supabase CLI, Docker, and project credentials are unavailable.

## Auth emails and redirects

In Supabase Auth settings, enable email confirmation, configure a production SMTP sender (the built-in sender is for development only), set an appropriate Site URL, and allow only the required redirect destinations:

- Web development: the exact local Flutter web origin ending in `/auth-callback`.
- Production web: `https://YOUR_DOMAIN/auth-callback`.
- Android/iOS: `com.deutschmate.app://login-callback/auth-callback`.

Set the public web route/fallback to serve `index.html` for `/auth-callback`. Test confirmation, expired links, reset, password update, and sign-out on web plus real iOS/Android devices before release. Native custom scheme and Android internet permission are configured in source, but deep links have not been tested on devices. Password minimum is 10 characters in the client; configure the matching server Auth password policy and rate limits.

## Remaining backend hardening

Review Supabase project region/data processing against launch markets and legal advice. Add account deletion/export and retention flows, abuse controls, SMTP deliverability, monitoring and backup/restore. Teacher application approval, booking transactions, payments, payouts, and admin operations still need server-side implementation. Keep the Supabase service-role key only in server-side secret storage.
