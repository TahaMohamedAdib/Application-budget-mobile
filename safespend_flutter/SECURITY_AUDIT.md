# SafeSpend — Security Audit

**Date:** 2026-09-17
**Scope:** `safespend_flutter/` — Flutter client, Supabase schema and policies, Deno Edge Function.
**Method:** Manual source review of the whole repository, targeted proof-of-concept tests, dependency review, and remediation with regression tests.

---

## Executive Summary

SafeSpend is a personal-finance app: a Flutter client talking directly to Supabase, with one Edge Function proxying an LLM. There is no traditional backend, so **Postgres Row Level Security is the only authorization boundary that matters**. That boundary was found to be correctly built — every one of the eleven user tables enables RLS with `auth.uid() = user_id` on all four verbs.

The serious problems were at the edges of that boundary rather than inside it:

- an **unauthenticated, world-callable Edge Function** that spends money on every request;
- **public storage buckets** holding receipt photographs;
- an **API key compiled into the mobile binary**;
- a **path-injection flaw** letting user input rewrite an outbound request URL.

Four of these are fixed in code. The API-key exposure is architectural and cannot be fixed by client changes alone; the migration path already exists in the codebase and is documented below.

Overall posture after remediation: **good for a solo-developer product, not yet ready for untrusted scale.** The main residual risks are operational (key rotation, deploy-time configuration) rather than structural.

---

## Architecture Reviewed

| Layer | Technology | Notes |
|---|---|---|
| Client | Flutter 3 / Dart, `provider` state | Ships to Android and iOS |
| Auth | Supabase GoTrue | Email + password, Google and Apple OAuth |
| Authorization | Postgres RLS | Sole enforcement point; no server tier |
| Database | Supabase Postgres | 11 user tables, all RLS-enabled |
| Storage | Supabase Storage | `receipts`, `logos` buckets |
| Serverless | Deno Edge Function (`chat`) | Proxies DeepSeek |
| AI | Gemini direct, or SafeSpend backend | Provider-switchable |
| Local secrets | `flutter_secure_storage` | Keychain / EncryptedSharedPreferences |
| CI/CD | None | No pipeline, no Docker, no IaC |

**Trust boundaries.** (1) Device to Supabase, crossed with a JWT and policed by RLS. (2) Device to Edge Function, previously uncontrolled. (3) Edge Function to DeepSeek, holding a server-side secret. (4) Device to Yahoo Finance, unauthenticated third party.

---

## Threat Model

**Assets.** Financial records (balances, transactions, debts, income), receipt images, AI conversation history, session tokens, the DeepSeek and Gemini API keys.

**Actors considered.** Anonymous internet users; authenticated users attacking other users' rows; someone holding an unlocked device; an attacker who has decompiled the APK; an automated bot hunting exposed endpoints.

**Explicitly assumed.** The mobile binary is readable. Any value compiled into it is public. The client can be modified, so no client-side check is a security control. Requests can be replayed and IDs manipulated.

**STRIDE highlights.** *Spoofing* is handled by GoTrue and, after this work, by token verification in the Edge Function. *Tampering* with row ownership is blocked by RLS. *Information disclosure* was the dominant real risk, via public buckets and a compiled-in key. *Denial of service / cost abuse* was unbounded on the chat function. *Elevation of privilege* through the AI tool layer was mostly prevented by design, with one gap now closed.

---

## Findings

| ID | Severity | Vulnerability | Component | CWE | Status |
|---|---|---|---|---|---|
| C-1 | CRITICAL | Unauthenticated Edge Function with wildcard CORS | `supabase/functions/chat/index.ts` | CWE-306 | **Fixed** |
| C-2 | CRITICAL | AI API key compiled into the mobile binary | `lib/services/ai/ai_config.dart` | CWE-798 | **Fixed** (rotation still required) |
| H-1 | HIGH | Receipt and logo buckets publicly readable | `supabase_complete_setup.sql` | CWE-200 | **Fixed** |
| H-2 | HIGH | Path injection via stock ticker and currency code | `lib/services/stock_price_service.dart` | CWE-23 | **Fixed** |
| M-1 | MEDIUM | AI tool `confirm()` skipped identity sanitisation | `lib/services/ai/tools/ai_tool_executor.dart` | CWE-807 | **Fixed** |
| M-2 | MEDIUM | Raw exception text returned to clients | `supabase/functions/chat/index.ts` | CWE-209 | **Fixed** |
| M-3 | MEDIUM | No attachment size or MIME allowlist | `lib/services/ai/ai_attachment.dart` | CWE-400 | **Fixed** |
| M-4 | MEDIUM | Discontinued and outdated dependencies | `pubspec.yaml` | CWE-1104 | **Documented** |
| M-5 | MEDIUM | `app_config` table had no RLS and was API-reachable | `20260415000000_storage_sync_trigger.sql` | CWE-732 | **Fixed** |
| M-6 | MEDIUM | `SECURITY DEFINER` function without pinned `search_path` | `supabase_complete_setup.sql` | CWE-426 | **Fixed** |
| L-1 | LOW | Certificate pins expire 2027-01-01 | `network_security_config.xml` | CWE-324 | **Documented** |
| L-2 | LOW | Prompt injection via user-controlled record names | `financial_context_service.dart` | CWE-74 | **Accepted, contained** |
| I-1 | INFO | PIN uses unstretched SHA-256 | `lib/services/app_lock_service.dart` | CWE-916 | **Accepted** |

---

### C-1 — Unauthenticated Edge Function (CRITICAL)

The `chat` function accepted any POST from any origin. It checked no token, applied no rate limit and set `Access-Control-Allow-Origin: '*'`.

**Attack scenario.** The function URL is discoverable from the client binary or from network traffic. An attacker scripts requests against it and every one bills the owner's DeepSeek account. There is no per-user attribution, so abuse is invisible until the bill arrives. Wildcard CORS additionally lets any website drive it from a visitor's browser.

**Impact.** Unbounded financial loss and a free LLM proxy operated at the owner's expense.

**Fix.** The function now verifies the caller's Supabase JWT against `/auth/v1/user` before doing any work, and derives the user id from that response rather than the request body. Added: an origin allowlist that denies by default, a 128 KB body cap, message-count and message-length limits, strict role validation, and a per-user sliding-window rate limit of 20 requests per minute.

**Verification.** Code review of every path; each rejection returns before the upstream `fetch`. Rate limiting is per-isolate, which is a mitigation rather than a guarantee — noted under Remaining Risks.

---

### C-2 — API key compiled into the binary (CRITICAL)

`GeminiAIService` reads `EnvConfig.geminiApiKey` and appends it to the request URL. The value arrives through `--dart-define` at build time, which places it in the compiled binary.

**Attack scenario.** Anyone who downloads the APK can extract the string. A key in a URL query string is additionally exposed to proxy and server logs along the path.

**Why this cannot be fixed in the client.** Obfuscation, encryption and native storage all fail against an attacker who controls the device: the app must recover the plaintext key to use it, so the attacker can too. The only real fix is to stop shipping the key.

**Fix applied — the capability was removed, not merely defaulted away.** `GeminiAIService` is deleted, the `gemini` enum arm is gone, and `EnvConfig.geminiApiKey` no longer exists. `GEMINI_API_KEY` was also removed from `.env.local`. There is no longer any code path that reads a model-provider key, so no build can ship one by configuration mistake.

This was the right call because the AI Coach is currently closed to all users behind a "coming soon" screen, so the key bought nothing. A dormant credential in a build input is pure downside.

For that default to be usable rather than merely safe, `AIConfig.baseUrl` falls back to the configured Supabase project's Edge Functions host, where the `chat` function already lives. It resolves to `{SUPABASE_URL}/functions/v1/chat`, which is exactly where the function is deployed, so a plain `flutter build apk` now produces a working Coach with the DeepSeek key held server-side and callers authenticated by their own Supabase session. A secure default that breaks the feature gets reverted, so this mattered.

Three supporting changes were needed:

- The Edge Function now speaks the documented `SafeSpendAIService` wire contract, returning `{conversation_id, type, text, tool_calls, suggestions, insights, usage}`. It previously returned `{reply}` only, which the client could not parse. It accepts both `text` and `content` on inbound messages, and still emits `reply` alongside the new shape, so a client mid-rollout is not broken.
- `EnvConfig.aiProvider` and `EnvConfig.aiBaseUrl` were **duplicate declarations** of the same build flags with their own defaults. After the change they disagreed with `AIConfig`: this file still believed the app was on Gemini while the factory had already built the backend service. They now delegate to `AIConfig`, so there is one source of truth. This kind of split is how a security default comes to look applied without being applied.
- Regression tests assert that `AIProvider` has exactly one value, that the backend is usable without extra flags, that the endpoint resolves to the Edge Function, and that the app never addresses a model-provider host directly. The first of these fails if anyone reintroduces a key-bearing provider.

**Still required.** Rotate the key that was previously shipped. Deleting the code cannot revoke a credential already extracted from a binary that was distributed. The old value is no longer in the repository, so retrieve it from the Google AI Studio console when revoking.

---

### H-1 — Publicly readable receipt storage (HIGH)

Both buckets were created with `public = true` and carried a policy granting `SELECT` on `bucket_id` alone, with no ownership predicate.

**Attack scenario.** Object paths are `{user_id}/{uuid}.jpg`. Any leaked, shared or logged URL is readable forever by anyone, with no session. A receipt reveals what someone bought, where and when.

**Fix.** Both buckets are now private. The unconditional read policies are dropped and replaced with owner-scoped ones matching `auth.uid()` against the first path segment. The client now mints one-hour signed URLs via a new `signedUrlFor` helper instead of calling `getPublicUrl`.

**Note for deployment.** Existing objects stay reachable through previously issued public URLs until the bucket setting is applied in the live project. Re-running the setup SQL is required, and the `ON CONFLICT` clause was changed to `DO UPDATE` so that re-running actually flips the existing buckets rather than silently doing nothing.

---

### H-2 — Path injection in market-data requests (HIGH)

Tickers, range tokens and currency codes were interpolated directly into request paths.

**Proof of concept, run before the fix:**

```
input:  A/../../v1/finance/search?q=x
result: https://query1.finance.yahoo.com/v8/V1/FINANCE/SEARCH?Q=X?interval=1d&range=1d

input:  A/../../../etc
result: https://query1.finance.yahoo.com/v8/ETC?interval=1d&range=1d
```

User input escaped the intended endpoint and retargeted the request.

**Fix.** Added `_safeSymbol`, which normalises and validates against `^[A-Z0-9][A-Z0-9._=-]{0,19}$`, plus patterns for range tokens and ISO 4217 currency codes. Every interpolation site now validates first and returns empty on rejection.

**Verification.** 13 attack vectors, including encoded traversal, null bytes, CRLF and scheme injection, are asserted to be rejected in `test/security_regression_test.dart`, alongside checks that ordinary tickers such as `BRK.B` and `EURUSD=X` still work.

---

### M-1 — AI tool confirmation bypassed sanitisation (MEDIUM)

`submit()` stripped identity arguments (`user_id`, `token`, and similar) and checked required parameters. `confirm()`, a separate public entry point, called `_run` directly and did neither. A tool call travels through UI state between the two steps.

**Fix.** `confirm()` now re-applies both the identity stripping and the required-argument validation rather than trusting that the call reaching it is the one that was screened.

---

### M-5 — Configuration table without RLS (MEDIUM)

Found on the **second audit pass**, after the first pass had focused on the eleven user-data tables.

`public.app_config` was created without `ENABLE ROW LEVEL SECURITY`. Supabase exposes the entire `public` schema through PostgREST, so a table with no RLS is reachable by any client holding the anon key — which ships in the app.

**Attack scenario.** The table stores `supabase_project_ref`, which the storage-sync trigger interpolates into generated object URLs. A writable config row would let an attacker point those URLs at a host they control, turning a receipt link into an attacker-controlled fetch.

**Fix.** RLS enabled with no policy, so ordinary roles get nothing, plus an explicit `REVOKE` from `anon` and `authenticated`. The `SECURITY DEFINER` trigger still reads it, because a definer function runs as the owner and bypasses RLS.

---

### M-6 — SECURITY DEFINER without pinned search_path (MEDIUM)

Also found on the second pass. `public.handle_new_user()` runs `SECURITY DEFINER` on every signup but did not pin `search_path`. Its sibling function in the storage migration did, which is what made the omission visible.

**Attack scenario.** A definer function resolves unqualified names using the caller's `search_path`. Someone able to create objects in an earlier schema could shadow `profiles` and capture writes intended for the real table.

**Fix.** `SET search_path = public, pg_temp` added, and the insert target is schema-qualified as a second layer.

---

### L-2 — Prompt injection (LOW, contained)

Account, category and goal names are user-controlled and flow into the AI prompt context. A user could name an account to inject instructions.

**Why the impact is limited.** The model is not an authorization boundary here. Every mutating tool returns `needsConfirmation` and executes only after explicit user approval, identity arguments are stripped, and all writes go through `AppProvider` rather than direct database access. A successful injection can therefore mislead the model's text, but cannot move money without the user tapping confirm. Since the injected names are the attacker's own, the blast radius is their own account.

---

### I-1 — PIN hashing (INFORMATIONAL, accepted)

The app-lock PIN is stored as `SHA-256(salt + pin)` with a 16-byte salt from `Random.secure()`. SHA-256 is fast, so a 4-digit space is exhaustible offline in moments.

**Why this is accepted.** The threat model is stated correctly in the source: this is a local gate on an already-authenticated session, not an authentication factor. It does not protect the Supabase token. An attacker who can dump the keychain has already defeated the device sandbox and holds the session token directly, making the PIN irrelevant. The salt is correct and prevents cross-user digest comparison. A future improvement would be PBKDF2 or Argon2id with a work factor.

---

## Fixed Vulnerabilities

| Finding | Files changed |
|---|---|
| C-1 | `supabase/functions/chat/index.ts` |
| H-1 | `supabase_complete_setup.sql`, `lib/services/supabase_sync_service.dart` |
| H-2 | `lib/services/stock_price_service.dart` |
| M-1 | `lib/services/ai/tools/ai_tool_executor.dart` |
| M-2 | `supabase/functions/chat/index.ts` |
| M-3 | `lib/services/ai/ai_attachment.dart`, `lib/screens/coach_screen.dart`, 16 locale files |
| M-5 | `supabase_migrations/20260415000000_storage_sync_trigger.sql` |
| M-6 | `supabase_complete_setup.sql` |
| C-2 | `lib/services/ai/gemini_ai_service.dart` (deleted), `ai_config.dart`, `ai_service_factory.dart`, `ai_service.dart`, `lib/services/env_config.dart`, `.env.local`, `supabase/functions/chat/index.ts`, `supabase/functions/chat/.env.example` |

---

## Remaining Risks

1. **The Gemini key must be rotated** if any build carrying it was distributed. New builds no longer ship it, but code changes cannot revoke a key already extracted from a binary that is already out.
2. **Edge Function rate limiting is per-isolate.** Deno may run several isolates, so the effective limit is a multiple of 20/min. Durable limiting belongs in Postgres or an API gateway.
3. **Existing storage objects** remain reachable via previously issued public URLs until the bucket change is applied to the live project.
4. **No CI/CD means no automated dependency scanning.** Nothing will flag a future CVE.
5. **`flutter_markdown` is discontinued.** It renders AI output; an unmaintained renderer handling untrusted text is a standing risk.
6. **No account lockout or CAPTCHA** on sign-in. Supabase applies some default throttling, but it has not been verified for this project.
7. **The pre-existing layout overflow** in `home_balance_card_test.dart` is unrelated to security and was confirmed present before this work.

---

## Dependency Risks

| Package | Current | Latest | Concern |
|---|---|---|---|
| `flutter_markdown` | 0.6.23 | 0.7.7+1 | **Discontinued.** Renders untrusted AI output. |
| `supabase_flutter` | 2.12.0 | 2.17.2 | Auth and storage client, 5 minor versions behind. |
| `flutter_secure_storage` | 10.0.0 | 11.2.0 | Stores the PIN digest. |
| `file_picker` | 8.3.7 | 13.1.0 | Five majors behind; handles untrusted file paths. |
| `fl_chart` | 0.68.0 | 1.2.0 | Presentation only. |

No known-exploited CVE was identified in the current set. Dart has no first-party `audit` command; this was assessed by version and maintenance status. Upgrades were **not** applied because `supabase_flutter`, `file_picker` and `fl_chart` all carry breaking changes, and shipping an unverified auth-client upgrade in a security pass would trade a documented risk for an unmeasured one.

---

## Secret Exposure

A repository-wide scan covered tracked files, provider-specific key formats (Stripe, AWS, Google, JWT, PEM blocks) and generic credential patterns.

| Item | Location | Status |
|---|---|---|
| Supabase anon key `sb_publishable_****L-pv` | `lib/services/env_config.dart` | **Not a finding.** Anon keys are designed to be public and are constrained by RLS. |
| Supabase project ref `timcta****kvlq` | Several files | **Not a finding.** Public by design. |
| Gemini API key | **Removed entirely** | The provider, the config field and the `.env.local` entry are all deleted. No code path reads a model key. Rotate the old value; see C-2. |
| DeepSeek API key | Not in source | **Correct.** Server-side Supabase secret. |
| `.env.local` | Working tree | **Correctly ignored and untracked.** Verified with `git check-ignore` and `git ls-files`. |

No live secret is committed to the repository. The only real exposure is C-2, which is a property of mobile distribution rather than of the source tree.

---

## Production Configuration Checklist

See `SECURITY_CHECKLIST.md`.

---

## Tests Performed

- **Static review** of all 117 Dart source files, the SQL schema and policies, the Edge Function, and the Android manifest and network configuration.
- **Secrets scan** across tracked files using provider-specific and generic patterns.
- **Proof-of-concept** for H-2, executed before remediation, demonstrating URL retargeting.
- **Regression suite** added: `test/security_regression_test.dart`, 25 tests covering path injection (13 vectors), currency validation, amount parsing, PIN salting and compiled-in configuration.
- **Full suite:** 1,915 tests. 1,914 pass; the single failure is a pre-existing layout overflow, confirmed by reverting all changes and reproducing it on unmodified `HEAD`.
- **Static analysis:** `flutter analyze` reports **0 errors** across `lib/`.

**Not performed.** Live penetration testing against the Supabase project, runtime RLS verification with two real accounts, APK decompilation, and TLS pin validation on a physical device. These need credentials and hardware outside this environment.

---

## Recommendations

**Do first.**
1. Rotate the Gemini API key if any build containing it was shared.
2. Apply the updated storage SQL to the live project and confirm both buckets report `public = false`.
3. Deploy the hardened Edge Function and set `ALLOWED_ORIGINS`.

**Do next.**
4. Migrate the Coach to `AI_PROVIDER=safespend` so no provider key ships in the binary.
5. Move rate limiting into Postgres so it holds across isolates.
6. Replace `flutter_markdown`; it is discontinued and renders untrusted text.
7. Verify RLS empirically with two accounts, attempting cross-user reads.

**Do when convenient.**
8. Upgrade `supabase_flutter` and `flutter_secure_storage` with a full regression run.
9. Add a scheduled dependency scan.
10. Set a calendar reminder before the 2027-01-01 certificate pin expiry.
11. Consider PBKDF2 or Argon2id for the app-lock PIN.

---

## Security Scores

| Domain | Score | What holds it back |
|---|---|---|
| Authentication | 82 | GoTrue is solid and sessions are stored in the keychain. No MFA; lockout behaviour unverified. |
| Authorization | 90 | RLS is correct and complete on all 11 tables. Not yet empirically verified against a live project. |
| API Security | 78 | Edge Function now authenticates, validates and limits. Rate limiting is per-isolate. |
| Input Validation | 85 | Path injection fixed, amounts bounded, attachments capped. Validation is client-side by architecture. |
| Data Protection | 80 | Buckets are private and URLs signed. Existing objects need the live fix applied. |
| Secrets Management | 85 | No model-provider key exists anywhere in the codebase or its build inputs, and no code path can read one. Held back only until the previously exposed key is rotated at the provider. |
| Dependency Security | 60 | No known exploited CVE. One discontinued package; several majors behind; no automated scanning. |
| Infrastructure | 70 | Pinning and cleartext blocking are configured. No CI/CD, no IaC, no monitoring. |
| Frontend / Mobile | 84 | `allowBackup=false`, no exported components, pinned TLS, keychain storage. Binary is inherently readable. |
| Backend | 80 | The single function is now hardened. RLS carries most of the load, which is a thin server tier. |
| Logging & Monitoring | 65 | All 43 log calls are `kDebugMode`-guarded, so nothing leaks in release. There is also no security logging or alerting. |
| CI/CD | 40 | Nothing exists to attack, and nothing exists to catch regressions. Neutral-to-poor rather than actively unsafe. |
| **Overall** | **80** | Authorization is genuinely well built, and the default build no longer ships a provider key. The ceiling is now set by dependency freshness, the absence of automated scanning, and the fact that several fixes need deploy-side action before they take effect. |

No domain scores 100. Authorization comes closest because RLS is correct by construction, but it is marked down for lacking empirical verification against a running database. Dependency Security is now the weakest area: one package is discontinued, several are majors behind, and nothing automated will flag the next CVE.
