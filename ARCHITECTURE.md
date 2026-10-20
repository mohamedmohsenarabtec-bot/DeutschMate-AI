# Architecture

## Existing browser reference

```text
index.html + styles.css + app.js
  └── browser localStorage
tests/smoke.ps1 ── Chrome DevTools Protocol ── temporary profile
```

The root client remains plain HTML/CSS/JavaScript with no package manifest, API, server, or database. Its original smoke suite passes 23 checks. Files and workflow remain preserved.

## Flutter application

```text
deutschmate_flutter/
  ├── lib/core/       localization, theme, models, guest/cloud repository boundary
  ├── lib/features/   learning UI/controller, account flows, AI tutor client
  ├── test/           widget, controller, repository-isolation tests
  ├── supabase/       schema migration, sample seed, pgTAP tests, Edge Function
  ├── android/        generated Android host with auth callback scheme
  ├── ios/            generated iOS host with auth callback scheme
  └── web/            generated Flutter web host
```

Flutter/Dart is the shared application client. Anonymous users use SharedPreferences on that device/browser. With build-time Supabase URL and publishable key, authenticated users use Supabase Auth and `student_progress` account rows; guest and account data are intentionally not merged. A load-generation guard prevents an earlier account's slower response from replacing the current account in memory.

## Backend source and security boundaries

The migration creates profile, curriculum pathway, learner progress, teacher application, notification, AI usage and audit tables. It enables RLS, denies client role elevation, limits profile updates to display name/locale, and scopes progress and teacher documents to owner identity. Admin authorization reads trusted `app_metadata`, which is not client-writable. Teacher verification files use a private bucket and UUID-prefixed paths.

The AI tutor client invokes `ai-tutor`; the function validates the user's Supabase access token, scopes conversation access to its owner, reserves quota and cost budget through service-role-only SQL functions, and records both sides of a successful turn with actual token usage. `OpenAiResponsesProvider` calls the OpenAI Responses API with server-only credentials and provider storage disabled. Deno tests cover validation, ownership, quotas, failures, output parsing, and retries.

The schema and function are source only: they have not been migrated/deployed into Supabase. CLI/Docker/Deno and project credentials are unavailable, so pgTAP, Deno, live security behavior, auth, sync, and AI remain unverified. There is no connected project. The A1–C2 seeds are sample outlines, not approved courses.

## Not yet connected / commercial target

```text
Flutter clients
  └── Supabase Auth + PostgreSQL/RLS + private Storage (client code/config ready, project absent)
       ├── Edge Function: AI tutor with quota/cost accounting + OpenAI adapter (implemented, not deployed)
       ├── trusted role/admin operations (not implemented)
       ├── transactional tutoring bookings and notifications (not implemented)
       ├── verified payments/refunds/entitlements (not implemented)
       └── production content and operations (not implemented)
```

Voice/video, payment, teacher scheduling, admin interface, full exam product, and production deployment are not connected. Public SEO pages need separate assessment; no server-rendered site is configured. For configuration and launch blockers, see `SUPABASE_SETUP.md`, `DEPLOYMENT.md`, and `IMPLEMENTATION_PLAN.md`.
