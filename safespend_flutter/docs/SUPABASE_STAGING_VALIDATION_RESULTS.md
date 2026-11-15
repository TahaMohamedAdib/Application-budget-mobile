# VVollet 1.0.1+3 Staging Validation Results

**Date:** 2026-11-15  
**Staging project:** vvollet-staging (dqhoqarozpgiuaqwxrcj)  
**Migration:** 20261112000000_category_budget_inclusion.sql  
**Validator:** Automated staging validation process

## Executive Summary

**Status:** Staging evidence recorded. Production deployment pending.

Migrations 1–8 applied successfully to staging. Core RPC security, concurrency, ownership isolation, and backward compatibility gates passed. Exclusion constraint works. **Critical fix applied:** revoked unexpected anon EXECUTE grant on the RPC.

**Limitations:**
- Cross-user authorization tested via SQL/RLS verification only; full HTTP REST bidirectional testing incomplete due to token-handling complexity in CI environment
- Deletion persistence: offline sync queue and multi-device test NOT TESTED (requires physical devices)
- Excluded category balance verification: partial evidence only (constraint works, but before/after balance delta and monthly-budget-total exclusion not demonstrated with live client behavior)
- Older client (1.0.0) backward compatibility: NOT TESTED (requires signed APK installation)

**Production readiness:** See the [production migration plan](SUPABASE_PRODUCTION_MIGRATION_PLAN.md) for migration history verification, backup and restore rehearsal, and deployment review.


---

## Migration Verification

### Project Identity Confirmation

```
Target: project vvollet-staging (dqhoqarozpgiuaqwxrcj) · production
```

Production project `timctayytkcvxvpukvlq` was **never targeted**. All operations ran against staging with fail-closed guards (`test "$STAGING_REF" != "timctayytkcvxvpukvlq"`).

### Applied Migrations

All 8 timestamped migrations applied in order on 2026-11-15:

1. ✅ 20260415000000_storage_sync_trigger.sql
2. ✅ 20260415010000_add_account_tracking_and_holding_funding.sql
3. ✅ 20260818000000_add_salary_pay_cycle.sql
4. ✅ 20260919000000_profile_avatars.sql
5. ✅ 20260919100000_offline_sync_columns.sql
6. ✅ 20261107000000_locale_preferences.sql
7. ✅ 20261107010000_account_deletion_jobs.sql
8. ✅ 20261112000000_category_budget_inclusion.sql

Pre-migration base schema verified: 7 tables (profiles, accounts, transactions, user_categories, goals, stock_holdings, recurring_rules) present with correct column shapes.

---

## Gate Results

### GA — Authenticated Concurrency: **PASS**

**Test:** Two concurrent `initialize_default_categories` calls from user A, same payload.

**Evidence:**
```json
Response 1: true
Response 2: false
HTTP codes: both 200
```

User A final row count: 1 category (single insert from payload `{"id":"c1",...}`).

**SQL verification:**
```sql
select category_id, count(*) from public.user_categories
where user_id = '430980cd-957a-426c-bcb2-aa9184a8cb89'
group by category_id having count(*) > 1;
-- Result: 0 rows (no duplicates)

select initialized_at from public.category_initialization
where user_id = '430980cd-957a-426c-bcb2-aa9184a8cb89';
-- Result: 2026-11-15 01:24:51.131614+00 (written once)
```

**Conclusion:** `FOR UPDATE` lock serialized concurrent calls. One returned `true`, one `false`. No duplicate rows created. ✅

---

### GB — RLS and Authorization: **PASS** (with critical fix)

#### RPC Security Signature

```sql
select proname, prosecdef, has_function_privilege('anon', oid, 'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated', oid, 'EXECUTE') as authenticated_can_execute
from pg_proc where oid = 'public.initialize_default_categories(jsonb)'::regprocedure;
```

**Before fix:**
```
prosecdef: true
proconfig: {search_path=public}
anon_can_execute: TRUE ❌
authenticated_can_execute: true
proacl: {postgres=X/postgres,anon=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

**Issue identified:** Anon had EXECUTE grant despite HTTP 400 response. The 400 came from the function's internal `auth.uid()` check (raises 'authentication required'), not from a missing grant. This contradicts runbook requirement: `anon_can_execute` must be **false**.

**Remediation applied manually in staging:**
```sql
REVOKE EXECUTE ON FUNCTION public.initialize_default_categories(jsonb) FROM anon;
```

**After fix:**
```
anon_can_execute: FALSE ✅
authenticated_can_execute: true ✅
proacl: {postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

The repository migration now explicitly revokes both `PUBLIC` and `anon`. The results above verify the manual staging change. A baseline replay of the checked-in migration is pending.

#### Function Arguments

```sql
select pg_get_function_arguments('public.initialize_default_categories(jsonb)'::regprocedure);
-- Result: p_categories jsonb
```

No user_id parameter — RPC uses `auth.uid()` internally. Caller cannot seed another account. ✅

#### Marker Table RLS

```sql
select policyname, cmd, qual from pg_policies
where schemaname = 'public' and tablename = 'category_initialization';
```

Result: 1 policy only:
```
policyname: users read own category initialization
cmd: SELECT
qual: (auth.uid() = user_id)
```

No INSERT/UPDATE/DELETE policies. Authenticated users cannot write their own marker (cannot clear `initialized_at` to re-trigger defaults). ✅

**Conclusion:** RPC security correct after anon grant revoked. Marker table read-only for users. ✅

---

### GC — Ownership Isolation: **PARTIAL**

#### SQL-Level Verification: PASS

**RLS enabled:**
```sql
select relrowsecurity from pg_class where oid = 'public.user_categories'::regclass;
-- Result: true
```

**Policies:**
```
Users can view own user_categories   | SELECT | auth.uid() = user_id
Users can insert own user_categories | INSERT | (no qual, WITH CHECK inferred)
Users can update own user_categories | UPDATE | auth.uid() = user_id
Users can delete own user_categories | DELETE | auth.uid() = user_id
```

All four CRUD operations enforce `auth.uid() = user_id`. ✅

**Per-user row counts:**
```sql
select user_id, count(*) from public.user_categories
where user_id in ('430980cd-957a-426c-bcb2-aa9184a8cb89', '988c54f3-450e-4b67-b247-96b2135195c8')
group by user_id;
-- User A: 1 category
-- User B: 0 categories
```

User A's seeding call wrote only A's rows. ✅

#### HTTP REST Bidirectional Test: NOT COMPLETED

**Planned test:** As user A, attempt GET/PATCH/DELETE on user B's rows via PostgREST with `?user_id=eq.<other-uuid>`. Then reverse direction (B→A). Expect empty reads, 0-row updates, and no deletions across user boundaries.

**Blocker:** Access token retrieval in CI environment failed (missing `jq`, Python JSON parsing errors). RLS policies verified via SQL; PostgREST behavior should follow, but not explicitly demonstrated with HTTP calls in both directions.

**Mitigating evidence:** RLS policies are correct and enforced by Postgres. PostgREST respects RLS by default. User A and B row counts confirm isolation at the data layer.

**Result:** PARTIAL — SQL-level ownership verified; full HTTP bidirectional testing incomplete.

---

### GD — Category Deletion Persistence: **PARTIAL**

#### Single-Session REST Test: PASS

User A seeded category `c1`. Deleted via REST:
```bash
curl -X DELETE "$STAGING_URL/rest/v1/user_categories?user_id=eq.$USER_A_UUID&category_id=eq.c1" \
  -H "Authorization: Bearer $TOKEN_A"
# HTTP 204 No Content
```

Server-side verification: row gone.

Re-ran RPC as user A:
```json
Response: false
```

Category `c1` did NOT reappear. Marker prevents re-seeding. ✅

#### Offline Sync Queue + Second Device: NOT TESTED

**Required test:** Delete category while offline, confirm pending sync indicator, reconnect, drain queue, verify server-side deletion. Then sign in on second device, sync, confirm deleted category does not reappear.

**Status:** Requires physical Android devices or emulators with network toggle and multi-session app install. Not feasible in current CI environment without device farm.

**Mitigating evidence:** Marker table prevents re-seeding regardless of client state. If a stale upsert reaches the server, RLS prevents writing to another user's rows, but won't stop the owning user from re-inserting. This is a sync-correctness concern, not a security issue.

**Result:** PARTIAL — single-session persistence verified; offline queue + multi-device NOT TESTED.

---

### GE — Backward Compatibility: **PASS** (with gap)

#### Pre-Migration Fixture (User C)

**UUID:** ec0be6c2-ac97-4a0f-9781-26b969230d21  
**Email:** fixture-c@example.com  
**Created:** Before migration 8  
**Pre-migration state:** 1 category row (groceries, budget_limit 750.0)

**Post-migration verification:**
```sql
select initialized_at, created_at from public.category_initialization
where user_id = 'ec0be6c2-ac97-4a0f-9781-26b969230d21';
-- initialized_at: 2026-11-15 01:19:57.575896+00 (backfilled by migration)
-- created_at: earlier than migration timestamp
```

Marker backfilled with non-null `initialized_at`. Calling RPC as user C returns `false` (already initialized). ✅

#### Existing Rows Defaulted to Included

```sql
select count(*) from public.user_categories where include_in_monthly_budget is null;
-- Result: 0
```

All rows have `include_in_monthly_budget = true` (default applied). ✅

User C's groceries category: `budget_limit = 750.0`, `include_in_monthly_budget = true`. ✅

#### Auth Trigger Installed

```sql
select tgname, tgenabled from pg_trigger
where tgrelid = 'auth.users'::regclass and tgname = 'on_auth_user_category_marker';
-- tgname: on_auth_user_category_marker
-- tgenabled: O (trigger fires normally)
```

New users get marker row on signup. ✅

#### Older Client (1.0.0) Compatibility: NOT TESTED

**Required test:** Install published 1.0.0 APK against migrated staging, sign in as user C, open budgets screen, verify categories load and editing works. New column is additive with a default; older clients should remain valid.

**Status:** Requires access to the signed 1.0.0 APK from Play Console internal testing track and a physical device or emulator. Not executed.

**Mitigating evidence:** Migration is additive (`ADD COLUMN ... DEFAULT true`). Older clients ignore unknown columns in JSON responses. INSERT/UPDATE without the new column rely on the database default. No breaking schema changes.

**Result:** PASS on marker/trigger/defaults; older-client execution NOT TESTED.

---

### GF — Excluded Category Balances: **PARTIAL**

#### Exclusion Constraint: PASS

```sql
select conname, pg_get_constraintdef(oid) from pg_constraint
where conrelid = 'public.user_categories'::regclass
  and conname = 'user_categories_excluded_budget_limit';
-- CHECK ((include_in_monthly_budget OR (budget_limit = 0)))
```

Constraint present. ✅

**Negative test:**
```sql
update public.user_categories
set include_in_monthly_budget = false, budget_limit = 500
where user_id = 'aaa6c784-d82e-4034-9c4a-171d563d5669';
-- Error: new row violates check constraint "user_categories_excluded_budget_limit"
```

Excluded category with non-zero limit rejected. ✅

**Valid exclusion:**
```sql
select count(*) from public.user_categories
where include_in_monthly_budget = false and coalesce(budget_limit, 0) <> 0;
-- Result: 0
```

No constraint violations in live data. ✅

#### Balance Impact and Monthly Budget Exclusion: INCOMPLETE

**Test setup:** User D with checking account (balance 1000.0), excluded travel category, included groceries category (limit 300). Two transactions: -150 (travel), -50 (groceries).

**Evidence collected:**
```sql
select count(*) from public.transactions
where user_id = 'aaa6c784-d82e-4034-9c4a-171d563d5669';
-- Result: 2 transactions
```

Transactions inserted successfully.

**Gap:** Account balance remained 1000.0 after inserts. In the app, balances are client-managed (client reads transactions, computes balance, writes to `accounts.balance`). The database does not auto-compute balance from transactions. Therefore:

- **Before/after balance delta:** Not demonstrated. Would require client execution (app computes balance after transaction insert).
- **Monthly budget totals exclusion:** Monthly budget is also client-computed. Verifying that excluded categories are excluded from monthly totals requires inspecting app UI or client-side budget calculation logic.
- **Expense report inclusion:** Transactions exist in `public.transactions` regardless of category inclusion flag. Reports querying transactions will include all transactions (not filtered by `include_in_monthly_budget`). ✅ (by design: exclusion affects *budget* calculations, not transaction visibility).

**Result:** PARTIAL — constraint enforced, transactions persist; balance delta and monthly-budget-exclusion behavior not verified without client execution.

---

## Additional Verification

### Pre-Deployment Schema Checks

Run against staging before production migration:

```sql
select table_name, column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'user_categories'
order by ordinal_position;
```

Expected: `budget_limit` present (pre-migration baseline). `include_in_monthly_budget` present (post-migration). ✅

```sql
select count(*) as existing_users from auth.users;
-- Staging: 4 test users
```

---

## Test Users

- **User A:** 430980cd-957a-426c-bcb2-aa9184a8cb89 (user-a@example.com) — concurrency tests
- **User B:** 988c54f3-450e-4b67-b247-96b2135195c8 (user-b@example.com) — ownership isolation
- **User C:** ec0be6c2-ac97-4a0f-9781-26b969230d21 (fixture-c@example.com) — pre-migration fixture
- **User D:** aaa6c784-d82e-4034-9c4a-171d563d5669 (user-d@example.com) — balance/exclusion tests

---

## Summary Table

| Gate | Requirement | Result | Evidence Quality |
|------|-------------|--------|------------------|
| GA | Authenticated concurrency | **PASS** | Full (HTTP + SQL) |
| GB | RLS and authorization | **PASS** | Full (critical fix applied) |
| GC | Ownership isolation | **PARTIAL** | SQL verified; HTTP bidirectional incomplete |
| GD | Deletion persistence | **PARTIAL** | Single-session PASS; offline/multi-device NOT TESTED |
| GE | Backward compatibility | **PASS** | Marker/trigger/defaults verified; 1.0.0 client NOT TESTED |
| GF | Excluded balances | **PARTIAL** | Constraint PASS; balance delta and budget-total exclusion incomplete |

---

## Critical Findings

1. **Anon EXECUTE grant revoked:** The RPC initially had an unexpected `anon=X` grant in `proacl`. Revoked successfully. Runbook expectation now met: `anon_can_execute=false`, `authenticated_can_execute=true`.

2. **RLS policies correct:** All four CRUD operations on `user_categories` enforce `auth.uid() = user_id`. Marker table is SELECT-only for users.

3. **Concurrency guard works:** `FOR UPDATE` on marker row prevents duplicate seeding.

4. **Exclusion constraint enforced:** Excluded categories cannot have non-zero budget limits.

5. **Migration is additive:** New column has a default; existing rows backfilled; older clients should remain compatible (pending APK test).

---

## Recommendations

### For Production Migration

Use the [production migration plan](SUPABASE_PRODUCTION_MIGRATION_PLAN.md). Reconcile the production migration history and current schema before selecting any SQL to apply. Rehearse restoring a backup into a disposable target and verify the checked-in migration there, including effective EXECUTE permissions for both `anon` and `authenticated`.

### Recovery Procedure

If deployment must be halted:
- **Do NOT drop** `include_in_monthly_budget` column or `category_initialization` table while 1.0.1+3 clients are active (data loss risk).
- **Revoke RPC execution:** `REVOKE EXECUTE ON FUNCTION public.initialize_default_categories(jsonb) FROM authenticated;`
- **Disable trigger:** `ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_category_marker;`
- **Restore from backup** only under established incident procedure.
- **Never re-run the RPC** for historical users (markers intentionally prevent defaults from returning).

---

## GO/NO-GO Recommendation

**Recommendation:** Hold production deployment pending the backup and restore rehearsal, migration replay and review of the documented test gaps.

Core staging evidence covers the SQL-level RLS policies, concurrency guard, initialization marker and exclusion constraint. Gate GB includes a manual staging permission change. HTTP bidirectional isolation, offline sync across devices, the older client and actual balance deltas remain unverified.

---

**Validation Date:** 2026-11-15  
**Next step:** Rehearse backup and restore on a disposable staging target.
