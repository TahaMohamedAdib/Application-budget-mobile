# VVollet pre-release audit (running report)

**Audit branch:** `audit/pre-release`  
**Started:** 2026-11-07  
**Scope completed:** Phase 1 — repository reconnaissance and baseline collection.

## Preliminary verdict

**NO-GO for a closed tester release at this point.** The Android release build is
explicitly configured to use the debug signing key. The app also does not meet the
first-launch device-language requirement: it defaults to English regardless of the
device locale. This is a running conclusion and will be revisited after the
remaining audit phases and fixes.

## Stack confirmation

| Area | Status | Evidence |
| --- | --- | --- |
| Flutter/Dart | Confirmed. Flutter SDK constraint is `>=3.0.0 <4.0.0`; installed baseline was Flutter 3.47.9 / Dart 3.13.7. | `safespend_flutter/pubspec.yaml:5-6`; command `flutter --version` |
| State and persistence | Confirmed: `provider`, `shared_preferences`, `sqflite`, and `flutter_secure_storage`. | `safespend_flutter/pubspec.yaml:12-34` |
| Backend | Confirmed in source/docs as Supabase client + Postgres/RLS + Storage + Edge Functions; live deployment is **not verified**. | `safespend_flutter/lib/services/*`, `supabase_complete_setup.sql`, `supabase/functions/` |
| Local-first/sync | Partially confirmed. The active provider CRUD path still calls `SupabaseSyncService`; the SQLite `SyncEngine`/queue is present but transitional. | `safespend_flutter/docs/APP_MAP.md` (Persistence and integrations) |
| i18n | Confirmed custom map-based catalogs with 16 language codes, not ARB files. | `safespend_flutter/lib/l10n/app_localizations.dart:63-79` |
| Android | Package ID is still `com.taha.safespend`; visible label is VVollet. | `safespend_flutter/android/app/build.gradle.kts:25`; `android/app/src/main/AndroidManifest.xml:10` |
| iOS | Deployment target is iOS 13.0. Visible display name is VVollet, but bundle name remains `safespend_flutter`. | `safespend_flutter/ios/Podfile:2`; `ios/Runner/Info.plist` |
| CI/CD | No tracked workflow was found under `.github/workflows`. | `git ls-files`; filesystem inspection |

## Baseline commands

| Command | Result |
| --- | --- |
| `flutter pub get` | Passed. One dependency is discontinued (`flutter_markdown`); Pub reports 95 constrained updates available. |
| `flutter analyze` | Completed: **403 diagnostics**, no analyzer errors. Diagnostics include unused code/imports, deprecated APIs (`withOpacity`), and style lints. |
| `flutter test --reporter expanded` | **NOT VERIFIED TO COMPLETION.** The runner advanced through at least 70 tests but the command-output collector expired before receiving its final exit status. It emitted repeated `MissingPluginException` diagnostics for SharedPreferences while individual tests continued. A repeatable test harness/CI run will be added and run during the test phase. |
| Debug/release Android and iOS builds | Not yet run in Phase 1. |

## Initial findings

| ID | Severity | Area | Finding | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| PRE-001 | BLOCKER | Release | Android `release` uses the debug signing configuration. | `safespend_flutter/android/app/build.gradle.kts:34-37` | Open |
| PRE-002 | HIGH | i18n | Initial `Settings.locale` and deserialization default to `en`; `MaterialApp` is forced to that value and the source contains no device-locale resolution callback or `PlatformDispatcher` lookup. | `lib/models/settings.dart:91,258`; `lib/main.dart:163-185`; `rg` evidence recorded in this report | Open |
| PRE-003 | MEDIUM | Quality | Static analysis is non-clean: 403 diagnostics. | `flutter analyze`, 2026-11-07 | Open |
| PRE-004 | HIGH | Test reliability | Unit-test baseline emits unmocked SharedPreferences `MissingPluginException`; final pass/fail is not yet reproducible in this environment. | `flutter test --reporter expanded`, early output | Open |
| PRE-005 | MEDIUM | Permissions | Android declares broad image-read permissions. Whether the current picker flow requires them has not been demonstrated. | `android/app/src/main/AndroidManifest.xml:6-7` | Open |

## Hypothesis disposition (initial)

| Prompt hypothesis | Initial disposition |
| --- | --- |
| Device language is not detected | **Confirmed in source.** Automated behavior tests and minimal fix pending. |
| Release uses debug signing | **Confirmed.** |
| In-app account deletion absent | **Refuted in source; NOT VERIFIED end-to-end.** UI invokes `AuthService.deleteAccount()`, which invokes `delete-account`. |
| Security checklist deployment items remain | **Not verified against live Supabase.** Source checklist still has deployment-side unchecked entries. |
| Closed Coach leaks network/permissions | **Partially supported as safe in source.** `_coachComingSoon` is true and prevents conversation loading; test coverage exists. Runtime/network proof pending. |
| Media permissions unnecessary | **Not verified.** |
| Windows/web release scope | **Not verified.** Targets are present but no release matrix/CI governs them. |
| Incomplete VVollet rebrand | **Confirmed candidate.** iOS bundle name and Android application ID retain legacy SafeSpend identifiers; user-visible impact must be assessed separately. |
| Transition test incompatibility | **Not yet investigated.** |
| No CI/CD | **Confirmed.** No tracked workflow found. |

## Phase 2–8 plan

1. Add a catalog-diff and locale-resolution test first, then fix device-language precedence with explicit-choice persistence.
2. Audit financial mutations, persistence, queue semantics, and Supabase mappings; build ledger-invariant tests before changing financial logic.
3. Inspect SQL/RLS and Edge Functions, scan tracked history for secrets, and distinguish source evidence from deployment-only verification.
4. Add minimal CI: analysis, deterministic tests, localization check, and Android release build; leave credentials/signing setup as documented secure CI inputs.
5. Exercise a release build, permissions, account deletion, Coach gating, branding, legal/site content, and accessibility within the capabilities of this environment.

## Phase 2 progress — locale selection

Implemented the precedence contract in source: a language selected in Settings
is marked explicitly and wins; otherwise the first supported locale in the
platform preference order is selected; an all-unsupported list falls back to
English. The intent marker and locale are persisted locally and added to the
Supabase profile mapping with migration
`supabase_migrations/20261107000000_locale_preferences.sql`.

Validation on 2026-11-07:

- `flutter test test/locale_preference_test.dart test/localization_catalog_test.dart`: **38 passed**.
- The catalog check confirms exact key parity, nonblank values, and placeholder
  parity across all 16 catalogs.
- Focused analysis found no errors; it retains 42 pre-existing style/info
  diagnostics in the large provider and sync-service files.

Still not verified: platform per-app language manifests, locale change after a
background resume, a live profile migration, and device-rendered RTL behavior.

Android 13+ per-app language metadata was added in
`android/app/src/main/res/xml/locales_config.xml` and referenced from the
manifest. A release AAB build was started twice but this environment did not
return a final Gradle exit status or artifact before its command capture
expired; build status remains **NOT VERIFIED**.

## Account deletion source review

The in-app Account screen invokes `AuthService.deleteAccount`, which calls the
`delete-account` Edge Function using the current JWT. The function derives the
user id from that token, ignores request body identity, deletes objects beneath
that user's prefix in `receipts`, `avatars`, and `logos`, then deletes the auth
user. User data tables and the AI conversation/project migration reference
`auth.users` with `ON DELETE CASCADE`.

**HIGH residual risk:** Storage deletion and auth deletion are separate,
non-transactional operations. If Storage removal succeeds but admin user
deletion fails, the account remains but its images are irreversibly gone. If a
later step fails, there is no durable deletion-job/retry record. This cannot be
validated or safely redesigned without an isolated Supabase test project and
deployment authority; it remains open.

## CI and test-harness progress

Added `.github/workflows/flutter-audit.yml`, pinned to Flutter 3.47.9. On pull
requests and protected branches it resolves packages, analyzes, runs all Flutter
tests (which includes the catalog-parity suite), builds a release AAB, and
uploads that artifact for review. This confirms compilation only until the
debug-signing finding is resolved with secure CI keystore inputs.

`safespend_flutter/tool/audit.ps1` provides the corresponding local command.
The previously observed SharedPreferences error in `ai_tool_executor_test.dart`
was a test setup defect: the test bound Flutter but did not install mock
preferences. It now does, and its 13 tests pass without the plugin exception.

## Android permissions and branding scan

Removed `READ_MEDIA_IMAGES` and legacy `READ_EXTERNAL_STORAGE` from the
manifest. The app uses `image_picker` and `file_picker`, whose system picker/
chooser flows do not need broad media-library access for the selected file.
`test/android_manifest_policy_test.dart` verifies those permissions stay absent
and that cleartext traffic remains disabled (2 tests pass).

No user-visible “SafeSpend” text was found in the Flutter UI. Remaining legacy
identifiers include Android/iOS application IDs, Dart package/import names,
the SQLite filename, and diagnostics provider IDs. `Info.plist`'s
`CFBundleName` was corrected to VVollet and is guarded by the manifest-policy
test (3 tests pass). Application/package IDs are not changed in this audit
because changing them creates a new store identity and breaks upgrade
continuity.

## Finance and offline baseline

`financial_integrity_audit_test.dart` and `core_feature_logic_test.dart` pass
with the locale-preference tests (**25 tests** in the targeted run). They cover
transfer reversal, Daret idempotency, goal/debt caps, recurrence limits,
account deletion reversal, fees, and net-worth treatment. The larger offline
persistence/provider run was started; all observed tests passed, but its first
run exposed the locale merge regression described above before completion. It
must be rerun in CI after this commit before it is recorded as a complete pass.

## Source hardening completed after audit findings

- Android release Gradle configuration no longer falls back to the debug key.
  It requires ignored `android/key.properties`, with an example file for local
  use. CI materializes that file only from encrypted keystore secrets and
  builds/uploads an AAB only when those secrets exist.
- Account deletion now persists an RLS-protected `account_deletion_jobs` row
  through requested, Storage-complete, auth-deletion, and failed states. A
  failed request is safe to retry; successful auth deletion cascades the job.

`release_guardrails_test.dart` has 2 passing static regression checks. Deno is
not installed in this workspace, so TypeScript type-checking and a real
Supabase job lifecycle remain **NOT VERIFIED**.

An unsigned `flutter build appbundle --release` now fails closed at Gradle
configuration with the expected release-signing message. Flutter also warns
that Gradle 8.14, AGP 8.11.1, and Kotlin 2.2.20 will soon lose support; this
is a tracked pre-release maintenance item, not upgraded automatically because
the coordinated Android build-tool upgrade needs a signed release regression
run.

## Limitations

No physical Android/iOS device, App Store/Play Console, Supabase management credentials, or non-production Supabase test project was provided. No statement about deployed RLS, bucket privacy, Edge Function behavior, production account deletion, OAuth configuration, email templates, or store-listing status should be inferred from source inspection alone.
