# Deployment status

## Verified artifacts

- Flutter web build: `deutschmate_flutter/build/web` (build passes). It is a local artifact only; no hosting, domain, HTTPS, cache, server routing, or post-deployment test is configured.
- Android release-mode APK: `deutschmate_flutter/build/app/outputs/flutter-apk/app-release.apk` (~52.2 MB). It uses the generated debug key; do not distribute as a Play Store release. Select the registered application ID and configure a protected production keystore/CI secret first.
- iOS project: `deutschmate_flutter/ios` with URL scheme. macOS/Xcode, Apple signing, simulator/device QA, and store setup are required; no iOS build was run on Windows.

## Supabase status

Auth, account-scoped sync, migration, seed, storage policies, pgTAP sources, and the AI tutor Edge Function are implemented. No project is connected; migration, SQL/Deno tests, auth, sync, and AI are not live or verified. Use `SUPABASE_SETUP.md` before configuring or deploying. Never put `service_role`, OpenAI, payment, or database credentials in Flutter or the web artifact.

## Release gates

Configure and test the AI deployment, then complete reviewed/licensed curriculum, teacher booking, payment entitlements/refunds, and administration. Complete security/RLS tests, real-device/deep-link QA, privacy and data-retention review, backups, monitoring, store disclosures, and rollback. No application has been published or released through an app store.
