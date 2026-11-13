# Pre-tester release audit — VVollet (Flutter, Android first)

You are a senior mobile engineer doing a release-readiness audit on VVollet, a personal-finance app, before it goes to closed testers on Google Play. Work like a reviewer whose name is on the release: verify every claim by running code or tests, never assume something works because the code looks right, and report what you actually observed.

The app is at `D:\Work\Freelance\BudgetApp\safespend_flutter`. The branch is `fix/android-parity`. A previous audit is in `D:\Work\Freelance\BudgetApp\audit\AUDIT_REPORT.md` and `FINDINGS.csv`. Read them first, re-check every item they mark as fixed, and don't re-report findings that are already closed.

---

## 0. Ground rules (read before touching anything)

- **Disk:** drive C: is full. Before every `flutter`/Gradle command, set
  `$env:TEMP = $env:TMP = 'D:\Work\Freelance\BudgetApp\.build-temp'` and
  `$env:GRADLE_OPTS = '-Djava.io.tmpdir=D:/Work/Freelance/BudgetApp/.build-temp'`.
  Earlier JVM crashes (`hs_err_pid*.log` in the repo root) came from this.
- **Release signing is done. Don't touch it.** `android/key.properties` and `C:\Users\taham\VVolletSigning\vvollet-upload.jks` are secrets. Never print, copy, rotate, or commit them. Never read `key.properties` into output. The upload certificate SHA-256 ends in `…02:B2:D5:A7`. Any release AAB you build must carry that fingerprint, so check it with `keytool -printcert -jarfile`.
- **Keep these identifiers:** the Android `applicationId` is `com.vvollet.app` to match the Play Console listing, and Play rejects any other value. The Kotlin `namespace` (`com.taha.safespend`), the Dart package `safespend_flutter`, and the other internal `safespend` names stay as they are on purpose. The user-facing brand is "VVollet".
- **Investments is intentionally marked "upcoming"** for this release (`wealth-investments-upcoming`). Don't re-enable it.
- **Known pre-existing test failures:** `test/feature_form_sheets_test.dart` (RenderFlex overflow in fr/en, missing `app-form-sheet-surface` key) and `test/home_balance_card_test.dart` (one overflow). Don't treat these as regressions. Do fix them if they turn out to be real user-visible overflows, because testers will see them.
- **Dart name collisions:** `Transaction` and `Category` clash with sqflite/Flutter exports. Add `hide` clauses up front in new files.
- **No production data:** never write test data into the production Supabase project or into real user accounts. Use a fake or in-memory backend, a local Supabase (`supabase start`), or a dedicated throwaway test account that you clean up afterwards. If you can't get a safe backend, test against fakes and say so in the report.
- **Don't commit or push.** Leave the changes in the working tree and list them. Don't modify `.gitignore` signing rules.

### The data-layer invariants (don't break them; verify they hold)
The app is offline-first. SQLite (`lib/data/local_database.dart`) is the source of truth. `lib/data/sync_queue.dart` is a durable outbox, and `lib/data/sync_engine.dart` is the single sync worker that pushes to Supabase.
1. Every mutation writes the entity row **and** enqueues its push in **one** DB transaction. The queue can never disagree with the data.
2. Queue payloads carry **full entity state**, not diffs, so retries after an ambiguous timeout are idempotent.
3. Conflict rule: **a dirty (unsynced) local row always beats a server row.** Unsynced local work must never be silently overwritten.
4. Legacy migration (`legacy_migration.dart`) imports with `markDirty: false` on purpose. Already-synced history must not be re-uploaded.
5. Darets are **local-only** (no remote table). Their queue entries complete without a network call and must not retry forever.

---

## 1. Baseline

1. `flutter pub get`, `flutter analyze` (record the error count; warnings and infos are acceptable), and the full `flutter test` suite. Record pass/fail counts and list every failure that is not one of the known pre-existing ones.
2. Map the features: for each screen in `lib/screens/**`, write down what data it reads and writes, which model in `lib/models/` it uses, and which repository/provider methods it calls (`lib/providers/app_provider.dart`, `lib/data/local_repository.dart`). This map drives sections 2 and 3.

---

## 2. Localization audit (the device language must drive the whole app)

There are 16 supported locales: `en fr ar es de pt it tr nl ru zh ja ko hi id pl` (`lib/l10n/app_localizations.dart`). Catalogs live in `lib/l10n/translations*.dart`. The device locale is resolved by `S.resolveDeviceLocale`, and the app locale is applied in `lib/main.dart`.

### 2.1 Default language follows the phone
Verify with tests, and on an emulator if one is available (`adb shell "setprop persist.sys.locale fr-FR; stop; start"` or the emulator's settings):
- On a fresh install with the phone set to each supported language, the app opens in that language. That includes the onboarding `language_selection_screen.dart`, which should preselect it.
- Regional and script variants map correctly: `fr_CA`→fr, `pt_BR`→pt, `zh_Hant_TW`→zh, `es_MX`→es, `ar_MA`→ar.
- Preference order is respected: phone languages `[xx-unsupported, de]` should give German, not English.
- An unsupported-only phone (for example Swahili) falls back to English deterministically.
- **Precedence:** once the user explicitly picks a language in onboarding or Settings › Language, that choice persists across restarts, app updates, and phone-language changes. Before the user has chosen, a phone-language change *should* be picked up on the next launch. Decide whether that is the current behavior and report it.
- Sign-out and sign-in, account deletion, and "clear data" don't reset the language unexpectedly, and they don't leave the app in a mixed state.

### 2.2 Every visible string follows the selected language
- **Hardcoded strings:** scan `lib/**` for user-facing string literals that bypass `S.of(context)`: `Text('…')`, `title: '…'`, `label:`, `hintText:`, `tooltip:`, `semanticsLabel:`, SnackBars, dialogs, `throw Exception('…')` messages that reach the UI, notification titles and bodies, share text, and chart labels. Exclude keys, routes, logs, and asset paths. List each hit with `file:line`. Fix them by adding keys to **all 16** catalogs.
- **Catalog completeness:** every key exists in every locale and isn't empty. No locale silently falls back to English. A value identical to the English one is suspicious unless it's a brand name or a number, so flag those. Placeholders (`{amount}`, `{name}`, …) match across locales. Extend `test/localization_catalog_test.dart` so CI enforces this.
- **Stale strings after a language change:** switch language at runtime in Settings and visit every screen without restarting. Look for widgets that cache translated text in `initState`, in `static`/`final` fields, in providers, or in models. Check that tab bar labels, bottom-sheet titles, already-open dialogs, and the app tour all update.
- **Platform widgets:** date pickers, time pickers, the copy/paste toolbar, and the back-button tooltip come from `GlobalMaterialLocalizations` and `GlobalCupertinoLocalizations`. Check that the delegates are registered and that they cover all 16 locales.
- **Formatting:** numbers, currency (decimal and grouping separators, symbol position), dates, month names, weekday names, and relative dates ("today", "yesterday") must use the *selected* locale via `intl`. They must not use the device locale or a hardcoded `'en_US'`. Grep for `DateFormat(` and `NumberFormat(` calls that are missing a locale argument.
- **Plurals and gender:** check counts such as "1 transaction" / "5 transactions", and especially plural forms in ar, ru, and pl.
- **Arabic RTL:** the whole layout mirrors, directional icons flip (back arrows, chevrons), and amounts and charts stay readable. Mixed LTR numbers inside RTL text must render correctly. Take screenshots of the main screens in `ar`.
- **Text expansion:** check for overflows in de, ru, pt, and fr (longest strings) and for CJK/Hindi glyph rendering. Run the widget tests at the smallest and largest phone sizes with text scale 1.3. No `RenderFlex overflowed` errors are allowed.
- **Strings produced off-screen:** local notifications (`lib/services/notifications/`) must be built in the selected language. Check what happens to notifications that were *already scheduled* when the user changes language: they should be rescheduled. AI coach replies (`lib/services/ai/`, `supabase/functions/chat`) should answer in the selected language, so check that the locale is sent to the backend. Error messages from Supabase and edge functions (`delete-account`), auth errors (`auth_screen.dart`), and validation messages must not show raw English or exception text.
- **Store and legal text:** legal and privacy screens (`translations_legal.dart`) exist in every locale. The app name shows as "VVollet" everywhere.

Deliverable for this section: a per-locale matrix (locale × screen → OK / issue) and the list of hardcoded strings you fixed.

---

## 3. Data persistence, sync, and caching audit

For **every feature** in the section 1 map, cover create, edit, delete, and every special action. That includes transactions (income, expense, transfer), accounts, categories, budgets, goals and contributions, recurring rules and subscriptions, personal debts, cash on hand, darets (local only), salary/income settings, and app settings. Holdings are out of scope while Investments is "upcoming", but confirm that no holding code path runs.

### 3.1 Automated end-to-end persistence tests
Extend `test/offline_persistence_test.dart` and `test/offline_provider_integration_test.dart`, or add `test/release_data_integrity_test.dart`. Use `sqflite_common_ffi` and a fake Supabase client that records requests and can be told to succeed, fail, time out after committing server-side, or go offline. Check the following for each feature:
1. After the action, the row is in SQLite with the correct values (amounts to the exact minor unit, dates, timezone, foreign keys) and has `dirty` set. A matching queue entry exists. Both came from the same transaction: force an exception between the two writes and assert that neither persisted.
2. The sync engine pushes it. The fake backend receives the full entity state, the row becomes clean, and the queue entry is removed.
3. **Offline:** do 20 mixed actions offline, then reconnect. Everything arrives in a valid order (parents before children, with deletes after creates), and there are no duplicates.
4. **Interruption:** kill the process between "request sent" and "response received", then restart. The retry must be idempotent, with no duplicate transaction on the server. Do the same with the kill in the middle of a multi-step operation, such as a transfer touching two accounts or a goal contribution touching a goal and a transaction. The result must be all-or-nothing.
5. **Retry and backoff:** with persistent 5xx errors the queue backs off and keeps the data. Neither a 4xx/validation error nor a poison entry should block the rest of the queue forever. Check how the user is told (the sync status badge).
6. **Conflicts:** edit offline, with the server holding a newer version of the same row. The local dirty row wins (invariant 3). With a clean local row and a newer server version, the server wins.
7. **Deletes:** a deleted item never comes back on the next pull. Check tombstones and soft deletes, both on this device and when a second device deleted it.
8. **Two devices:** simulate device A and device B on the same account. Each one's changes show up on the other after a pull, without data loss.
9. **Totals:** after all of the above, account balances, budget spent, goal progress, and the spending/today screen totals equal a recomputation from the raw transactions. `test/financial_integrity_audit_test.dart` is the starting point.
10. **Session edges:** signing out with unsynced work warns the user (`unsynced_work_guard_test.dart`). Signing in as a different user never shows the previous user's data, so SQLite has to be wiped or partitioned. Account deletion removes the server and local data. Legacy migration imports old SharedPreferences data exactly once, without marking it dirty.

### 3.2 Caching: don't reload data that didn't change
- Cold start renders from SQLite immediately, without waiting on the network. Measure time to first meaningful frame offline and online.
- The pull is **incremental**, using an `updated_at` cursor or equivalent. A second launch with no server changes must download zero (or near zero) entity rows. Instrument the fake client, or log real requests, and report the request count and payload size for: first launch after login, second launch with no changes, and a launch after one remote change.
- There are no redundant fetches: tab switches, `didChangeDependencies`, provider rebuilds, and pull-to-refresh loops must not re-query the server. Find any `notifyListeners` storm that re-reads the whole database on every change.
- Images and attachments (`image_service.dart`) are cached on disk and are not downloaded again.
- Settings (scalar values in SharedPreferences) and SQLite stay consistent after a crash.

### 3.3 Run it for real
If an Android emulator or device is available, build a `--profile` APK. Then go through a scripted session: sign up, onboarding, add an account, add 10 transactions, add a budget, a goal, and a recurring rule, enable airplane mode, add 5 more, force-stop the app, disable airplane mode, and relaunch. Confirm that everything is on the server, using the throwaway account or local Supabase. Capture logcat for exceptions. If no emulator is available, say so explicitly, because the automated tests then stand in for this.

---

## 4. The rest of the senior release audit

Rank everything you find by severity. **P0** means a blocker for testers: data loss, crash, security, or a store rejection. **P1** means a tester will hit it. **P2** means polish.

- **Backend security:** check Supabase RLS on every table. A user can only read and write their own rows: write a test that tries cross-user access with a second JWT. Check edge functions (`supabase/functions/chat`, `delete-account`): they verify the JWT, validate input, enforce a rate limit or cost cap on the AI proxy, and keep secrets out of logs and responses. Confirm that no service-role key or AI API key ships in the APK: unzip the release AAB and grep it.
- **On-device security:** tokens are kept in `flutter_secure_storage`. App lock and PIN (`app_lock_service.dart`) can't be bypassed through the app switcher or a deep link. Screenshots are blocked on sensitive screens if that's intended. Release builds don't log financial data or tokens.
- **Money correctness:** amounts are stored as integer minor units or decimals, never `double` arithmetic for totals. Multi-currency handling and the currency-format screen work. The salary cycle and month boundaries behave across timezones and DST (`salary_cycle_test.dart`). Recurring rules don't double-fire after a missed period.
- **Stability:** look for unhandled async errors, a missing global error handler (`FlutterError.onError`, `PlatformDispatcher.onError`), `setState` after dispose, null crashes on empty states (new user, zero accounts, no network on first launch), and big datasets (5k transactions): scrolling performance and query indexes.
- **Notifications:** Android 13+ permission flow, exact-alarm policy, behavior after reboot, and no duplicate notifications.
- **Play compliance:** `targetSdk` meets current Play requirements. Declared permissions are all justified (`android_manifest_policy_test.dart`). The data-safety answers match the actual data collected and the in-app privacy summary. In-app account deletion works, along with the web deletion URL. `versionCode` must be bumped for every upload (currently `1.0.0+1`).
- **Accessibility:** semantics labels on icon buttons, contrast in light and dark themes, tap targets of at least 48dp, and no clipped text at large font scale.
- **Release build:** run `flutter build appbundle --release` (with the temp vars from section 0), then verify the signer fingerprint and the AAB size. Note: Flutter may print "failed to strip debug symbols" even when the bundle is fine. Check that `base/lib/*/libapp.so` exists and that `BUNDLE-METADATA/.../*.sym` files are present before treating that message as an error. Check that R8/minify doesn't break JSON or model serialization in release mode by running the release APK through the scripted session.

---

## 5. Fixing policy

- Fix every P0 and every P1 you can fix safely. Each fix gets a test that fails before the fix and passes after it.
- Don't refactor working architecture. Don't change the sync invariants. If one seems wrong, write it up as a finding instead of changing it.
- After the fixes, rerun `flutter analyze` and the full test suite, then rebuild the release AAB and re-verify the signer.

## 6. Deliverable

Write `D:\Work\Freelance\BudgetApp\audit\PRE_TESTER_AUDIT.md` with:
1. **Verdict:** ready for testers, ready with caveats, or not ready, and why, in three sentences.
2. Test results before and after (counts plus new failures), and the analyze error count.
3. Localization matrix (locale × screen) and the hardcoded strings fixed.
4. Per-feature persistence/sync table with columns: feature | local write | queued atomically | pushed | offline-replay | interrupt-safe | conflict-correct | delete-safe | cached/no-refetch. Each cell is ✅, ❌, or "not tested" (with the reason).
5. Network numbers for caching (requests and bytes for cold, warm, and one-change launches).
6. Findings table: ID | severity | area | `file:line` | what happens | how you reproduced it | fixed? (with the test name).
7. Every file you changed, and anything you could not verify, with the reason.

Be explicit about what you ran versus what you inferred. Mark any claim you didn't run as "inferred".
