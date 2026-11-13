# VVollet — Production Security Checklist

Deployment-side actions. Code fixes from the audit are already in the repository; the items here take effect only when applied to the live Supabase project, the build pipeline, or the store listing.

Companion document: `SECURITY_AUDIT.md`.

---

## Blocking — do before the next public build

- [ ] **Revoke the old Gemini API key at Google AI Studio.** The key, its config field and the whole Gemini provider are deleted from the codebase, but that does not revoke a credential already extracted from a build you released. This is now the only outstanding action for C-2.
- [ ] **Confirm no build script still passes `GEMINI_API_KEY`.** Nothing reads it any more, so a stale `--dart-define` is harmless, but it should not linger where someone might restore the matching code.
- [ ] **Apply the updated storage SQL** to the live project, then confirm both buckets are private:
      `select id, public from storage.buckets where id in ('receipts','logos');` — both must report `false`.
- [ ] **Confirm the old read policies are gone.** `Receipts public read` and `Logos public read` must not appear in `pg_policies`; `Receipts owner read` and `Logos owner read` must.
- [ ] **Deploy the hardened `chat` function** and verify an unauthenticated POST returns `401`.
- [ ] **Set `ALLOWED_ORIGINS`** for the chat function. Leave it empty if only native clients call it — empty denies all browser origins.
- [ ] **Verify `DEEPSEEK_API_KEY`** is set as a Supabase secret and appears in no source file or build artefact.

---

## Secrets and configuration

- [ ] `.env.local` is gitignored and untracked. *(Verified at audit time.)*
- [ ] No real credential appears in any `.env.example`; placeholders only.
- [ ] Build keys are injected via `--dart-define-from-file`, never committed.
- [ ] A rotation owner and schedule exist for every third-party key.
- [ ] Previously distributed builds are inventoried, so it is known which keys are already public.

## Authentication

- [ ] Email confirmation is required before an account becomes usable.
- [ ] Password-reset tokens are single-use and short-lived (Supabase default; confirm in dashboard).
- [ ] Sign-in throttling or lockout is enabled and tested against repeated failures.
- [ ] Session and refresh token lifetimes are set deliberately rather than left at defaults.
- [ ] OAuth redirect URLs are restricted to the app's own scheme; no open redirect.
- [ ] MFA considered for accounts holding financial data.

## Authorization

- [ ] RLS is enabled on every user table. *(Verified in schema: 11/11.)*
- [ ] **Empirically test cross-user access:** sign in as user A, attempt to read and write user B's rows by id, and confirm every attempt fails.
- [ ] No table grants `anon` more than it needs.
- [ ] `SECURITY DEFINER` functions all pin `search_path`. *(Fixed in source; re-run the setup SQL to apply.)*
- [ ] **Every table in `public` has RLS enabled**, including non-user tables. Verify with:
      `select tablename, rowsecurity from pg_tables where schemaname='public';` — all must be `true`.
      *(`app_config` was missing it; fixed in source, needs the migration applied.)*
- [ ] Storage policies key off `auth.uid()` for every verb, not just writes.

## Database

- [ ] Automated backups are on, with a known retention window.
- [ ] A restore has actually been rehearsed at least once.
- [ ] Connection strings and the service-role key live only server-side.
- [ ] The service-role key is never present in any client build.
- [ ] Migrations are applied through a reviewed process rather than ad-hoc SQL.

## Storage

- [ ] `receipts` and `logos` are private.
- [ ] Clients read through signed URLs with a bounded lifetime (currently one hour).
- [ ] Bucket MIME allowlists and size limits are enforced server-side.
- [ ] Object paths remain server-generated; no client-supplied filenames.

## API and Edge Functions

- [ ] Every function verifies the caller's JWT before doing work.
- [ ] Request bodies are size-capped.
- [ ] Payloads are schema-validated; unexpected shapes are rejected.
- [ ] Rate limiting is durable across isolates, not just in-memory.
- [ ] Errors returned to clients are generic; detail stays in server logs.

## Transport and network

- [ ] HTTPS everywhere; cleartext disabled. *(Configured on Android.)*
- [ ] Certificate pins are current — **the present set expires 2027-01-01.**
- [ ] A pin-rotation reminder is scheduled well before that date.
- [ ] iOS App Transport Security has no broad exceptions.

## Mobile hardening

- [ ] `allowBackup="false"`. *(Verified.)*
- [ ] No unnecessary exported components. *(Verified: only the launcher activity.)*
- [ ] Deep-link host and scheme are constrained. *(Verified.)*
- [ ] Release builds are obfuscated (`--obfuscate --split-debug-info`).
- [ ] Screenshot protection considered for screens showing balances.
- [ ] Release builds are signed with a real keystore, **not the Android debug key.**

## Logging and monitoring

- [ ] No secret, token or password is logged. *(All 43 call sites are `kDebugMode`-guarded.)*
- [ ] Edge Function logs carry no full request bodies containing financial data.
- [ ] Failed-authentication and unusual-access alerting exists.
- [ ] Someone is responsible for reading the alerts.

## Dependencies and supply chain

- [ ] `pubspec.lock` is committed.
- [ ] `flutter_markdown` is replaced; it is discontinued and renders untrusted AI output.
- [ ] `supabase_flutter` is upgraded after a full regression run.
- [ ] A scheduled dependency review exists, since there is no CI to automate it.

## Privacy

- [ ] Data collection is minimised to what the product needs.
- [ ] A user-facing data export exists. *(Present in settings.)*
- [ ] Account deletion removes rows **and** stored objects.
- [ ] A privacy policy matches what the app actually collects, including AI processing.
- [ ] Users are told their financial summary is sent to a third-party model.

## Incident response

- [ ] A documented key-rotation procedure exists for each provider.
- [ ] A way to revoke all sessions is known and tested.
- [ ] Contact route for security reports is published.
- [ ] A rollback path exists for a bad release.

---

## Verified during the audit

These needed no action and are recorded so they are not re-litigated:

- RLS enabled with correct `auth.uid()` predicates on all 11 user tables.
- `.env.local` gitignored and untracked; no live secret committed.
- PIN stored salted and hashed, never in plaintext.
- All logging debug-guarded, so release builds emit nothing.
- Upload paths server-generated under a per-user folder; no traversal possible.
- Transaction amounts bounded and validated against non-finite input.
- AI mutations require explicit user confirmation; identity arguments stripped on both entry points.
- Cleartext traffic blocked and certificate pinning configured on Android.
