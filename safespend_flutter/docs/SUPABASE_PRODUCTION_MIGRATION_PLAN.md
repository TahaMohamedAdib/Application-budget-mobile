# VVollet 1.0.1+3 Production Migration Plan

**Target:** Supabase production project `timctayytkcvxvpukvlq`  
**Migration:** Category budget inclusion (20261112000000) + dependencies  
**Status:** Pending rehearsal and production approval

---

## Pre-Flight Checklist

### 1. Staging Validation

- [x] Gates GA–GF executed with documented evidence
- [x] Critical anon EXECUTE grant issue identified and remediation procedure validated
- [x] RLS policies verified
- [x] Concurrency guard tested
- [x] Exclusion constraint enforced
- [x] Backward compatibility confirmed (marker/trigger/defaults)
- [ ] Checked-in migration replayed on a pre-migration test baseline and effective grants verified
- [ ] Test gaps reviewed and resolved or explicitly accepted

### 2. Production Preparation

- [ ] Maintenance window scheduled and communicated to users
- [ ] Backup procedure tested in staging (see Backup Strategy below)
- [ ] Rollback procedure documented and validated
- [ ] On-call engineer identified for post-migration monitoring
- [ ] Incident response plan reviewed

### 3. Required Access

- [ ] Confirmed access to the intended project and its approved migration workflow
- [ ] Production database credentials available (for backup verification)
- [ ] Admin access to Supabase dashboard (for manual verification)
- [ ] GitHub repository write access (for recording migration history)

---

## Migration Order

These eight timestamped files define the order for missing migrations, after the base schema exists:

1. `20260415000000_storage_sync_trigger.sql`
2. `20260415010000_add_account_tracking_and_holding_funding.sql`
3. `20260818000000_add_salary_pay_cycle.sql`
4. `20260919000000_profile_avatars.sql`
5. `20260919100000_offline_sync_columns.sql`
6. `20261107000000_locale_preferences.sql`
7. `20261107010000_account_deletion_jobs.sql`
8. `20261112000000_category_budget_inclusion.sql`

Reconcile the recorded migration history against the deployed schema before choosing which missing migrations to apply. The files are stored in [supabase_migrations](../supabase_migrations). Confirm that the approved deployment tooling reads this path and how it records applied versions.

---

## Backup Strategy

### Before Migration

Choose the backup method supported by the production project and confirm the recovery point. For a Supabase-managed database backup, verify whether it includes the data needed for recovery. Supabase database backups do not include Storage object contents, so account for those separately if needed. For a logical backup, back up the required roles, schema and data using the documented Supabase procedure. A default `supabase db dump` is schema-only.

### Backup Restoration Test

1. Prepare a disposable non-production restore target. Record the source and destination project refs from their Supabase dashboards. The destination must differ from both production and the existing staging project that holds the validation evidence.
2. Capture representative staging fixtures using the planned backup method. Record counts and representative values for auth users, categories, transactions and initialization markers, along with expected policies and grants.
3. Restore the backup into the disposable target using the same method planned for production recovery. Compare schema, row counts, fixture values and permissions. Run an authentication and category read smoke test. Record the result and evidence with secrets redacted.
4. To rehearse the migration, start from a separate pre-migration baseline on a disposable target. Apply the repository SQL through the planned deployment mechanism. Run the post-migration checks and verify effective permissions for `anon` and `authenticated`.

**Restore and migration replay:** Pending.

---

## Migration Procedure

### Step 1: Verify Migration History

Confirm project ref `timctayytkcvxvpukvlq` in the Supabase dashboard before opening the production SQL Editor. Reconcile the recorded versions with the deployed schema and the files listed above. The Supabase CLI ledger, where used, is `supabase_migrations.schema_migrations`. If the project has no ledger, reconcile earlier SQL Editor changes against release records and schema evidence. Investigate any discrepancy before applying SQL.

### Step 2: Verify the Baseline

Record the production schema and representative counts before making changes. Confirm that `public.user_categories` and its `budget_limit` column exist. Check for `include_in_monthly_budget`, `public.category_initialization`, the trigger and the RPC. If migration objects already exist or the history and schema disagree, review their state before selecting the deployment SQL.

### Step 3: Apply the Confirmed Pending Migration

After the restore rehearsal, migration replay and production review, apply the reviewed repository SQL using the approved deployment mechanism. Verify the actual target project ref immediately before executing. If the first seven migrations are already applied and migration 8 is pending, apply [migration 8](../supabase_migrations/20261112000000_category_budget_inclusion.sql). Record the applied version through the project’s migration tracking process. Stop and diagnose any execution error before continuing.

### Step 4: Post-Migration Verification

**Purpose:** Confirm migration 8 applied correctly and all safety mechanisms are in place.

Run the following read-only queries in the verified project's SQL Editor.

```sql
-- 1. Verify new column exists and has correct default
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_categories'
  and column_name = 'include_in_monthly_budget';

-- 2. Verify no row has a null inclusion flag
select count(*) as rows_with_null_inclusion
from public.user_categories
where include_in_monthly_budget is null;

-- 3. Verify marker table exists and has RLS enabled
select tablename, rowsecurity as rls_enabled
from pg_tables
where schemaname = 'public' and tablename = 'category_initialization';

-- 4. Verify the owner-scoped SELECT policy
select policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'category_initialization';

-- 5. Verify auth trigger is installed and enabled
select tgname, tgenabled
from pg_trigger
where tgrelid = 'auth.users'::regclass
  and tgname = 'on_auth_user_category_marker';

-- 6. Verify every account has a marker
select count(*) as users_missing_marker
from auth.users u
left join public.category_initialization ci on ci.user_id = u.id
where ci.user_id is null;

-- 7. Verify exclusion constraint exists
select conname, pg_get_constraintdef(oid) as constraint_def
from pg_constraint
where conrelid = 'public.user_categories'::regclass
  and conname = 'user_categories_excluded_budget_limit';

-- 8. Verify RPC function exists
select proname, prosecdef as security_definer
from pg_proc
where oid = 'public.initialize_default_categories(jsonb)'::regprocedure;
```

**Save `post_migration_verification.log` with the release record.**

**Expected Results:**
- `include_in_monthly_budget` column exists with type `boolean`, default `true`
- Zero rows with null `include_in_monthly_budget`
- `category_initialization` table exists with `relrowsecurity = true`
- Exactly 1 policy on `category_initialization` (SELECT-only)
- Trigger `on_auth_user_category_marker` exists with `tgenabled = 'O'`
- Zero accounts missing a marker. Compare pre-migration fixtures to confirm their `initialized_at` was backfilled
- Constraint `user_categories_excluded_budget_limit` exists with correct definition
- RPC `initialize_default_categories` exists with `prosecdef = true`

**If any check fails:** STOP. Consult rollback procedure.

---

### Step 5: Verify RPC Permissions

The migration revokes execution from `PUBLIC` and `anon` and grants execution to `authenticated`. Verify the effective privileges in the confirmed target project.

```sql
select
  has_function_privilege('anon', 'public.initialize_default_categories(jsonb)', 'EXECUTE')
    as anon_can_execute,
  has_function_privilege('authenticated', 'public.initialize_default_categories(jsonb)', 'EXECUTE')
    as authenticated_can_execute;
```

Require `anon_can_execute = false` and `authenticated_can_execute = true`. If either check fails, stop the rollout and inspect direct, `PUBLIC` and inherited grants.

### Step 6: Smoke Test

Use a disposable account authenticated as a normal user. Confirm the first category initialization returns `true`, creates the expected categories and writes the initialization marker. Confirm a second call returns `false` and creates no duplicates. Remove the test account after verification. Stop the rollout if the smoke test fails.

### Step 7: Record the Migration

Record the applied version, verified project, time, reviewed commit, pre- and post-migration evidence, and sign-off in the deployment record. Redact credentials and test account identifiers.

---

## Post-Deployment Monitoring

### First 24 Hours

Monitor these metrics and logs:

1. **Category seeding:** Review real RPC outcomes and error logs. Marker insertion counts measure account creation and do not measure RPC call volume or success.

2. **User-reported issues:**
   - Watch support channels for reports of missing categories, budget errors, or login failures
   - Check error tracking (Sentry, Rollbar, etc.) for new exceptions related to categories or RPC calls

3. **Database errors:** Use project database logs to track SQLSTATE `23514` and errors mentioning `user_categories_excluded_budget_limit`.

4. **Client version distribution:**
   - Track how many users are on 1.0.1+3 vs older versions
   - Verify older clients (1.0.0, 1.0.1+2) still function correctly (categories load, editing works)

### Week 1

1. Verify no duplicate category rows created (concurrency regression check):
   ```sql
   select user_id, category_id, count(*)
   from public.user_categories
   group by user_id, category_id
   having count(*) > 1;
   ```

2. Verify no orphaned marker rows (marker without user):
   ```sql
   select ci.user_id
   from public.category_initialization ci
   left join auth.users u on ci.user_id = u.id
   where u.id is null;
   ```

3. Check for excluded categories with balance impact anomalies:
   - User reports of incorrect account balances
   - Budget screen showing excluded categories in monthly totals (client-side bug)

---

## Rollback Procedure

**When to roll back:**
- Smoke test fails
- High error rate in first hour post-deployment
- Data corruption detected (duplicate rows, missing markers)
- Widespread user-reported issues

**How to roll back:**

### Option 1: Disable Category Seeding

If the RPC is the problem, disable execution for the affected API roles while preserving data and the inclusion column. Keep the auth trigger available to record new accounts unless the incident involves the trigger. If the trigger is disabled, record accounts created during that window and plan how to create missing markers before restoring seeding. Verify access and client behavior after any change.

### Option 2: Restore from Backup

Follow the approved and rehearsed restore procedure after confirming the actual target and recovery point. Quantify writes made after that point, plan for their loss or reconciliation, and coordinate app compatibility. A pre-migration restore removes `include_in_monthly_budget`, which the newer client expects when writing categories.

### Option 3: Repair Specific Data

Identify affected rows with a read-only query. Rehearse a narrowly scoped repair on fixtures and get incident approval before changing production data.

## Recovery Post-Rollback

**Never re-run the RPC for historical users.** The marker intentionally prevents defaults from returning. If a user's categories are missing after a rollback:

1. **Check if the user existed before the migration.** If yes, they should have categories from before the migration (restored from backup).
2. **Check if the user was created during the migration window.** If yes and their categories are missing, their signup may have been incomplete. They can re-create categories manually via the app.
3. **Do not call `initialize_default_categories` for users with `initialized_at` set.** The RPC will return `false` and do nothing.

For users genuinely missing categories after a clean rollback (backup restore), verify the backup integrity and escalate to database administration.

---

## Communication Plan

### Before Migration

**Internal:**
- Notify engineering team 48 hours before maintenance window
- Brief on-call engineer on rollback procedure
- Confirm incident response contacts are available

**External (if user-facing downtime expected):**
- Post maintenance notice in app (if in-app messaging available)
- Email users 24 hours before (optional, depending on downtime duration)
- Status page update (if applicable)

### During Migration

**Internal:**
- Post in #engineering Slack: "VVollet production migration in progress. ETA 30 minutes. Do not deploy unrelated changes."
- Live updates in incident channel if issues arise

### After Migration

**Internal:**
- Post in #engineering Slack: "VVollet production migration complete. Monitoring for 24 hours."
- Share smoke test results and verification logs

**External:**
- Mark maintenance window as complete on status page
- If rollback occurred, communicate impact and timeline for retry

---

## Appendix: Migration 8 SQL Summary

`20261112000000_category_budget_inclusion.sql` performs these operations:

1. Adds `include_in_monthly_budget boolean not null default true` column to `public.user_categories`
2. Creates check constraint `user_categories_excluded_budget_limit`: `CHECK ((include_in_monthly_budget OR (budget_limit = 0)))`
3. Creates table `public.category_initialization` with columns `user_id`, `initialized_at`, `created_at`
4. Enables RLS on `category_initialization` with SELECT-only policy `auth.uid() = user_id`
5. Backfills `category_initialization` with all existing `auth.users` (sets `initialized_at = now()` for all)
6. Creates trigger `on_auth_user_category_marker` on `auth.users` (AFTER INSERT) to auto-insert marker rows for new signups
7. Creates function `public.initialize_default_categories(jsonb)` with SECURITY DEFINER, uses `auth.uid()`, locks marker row with `FOR UPDATE`, inserts categories only if `initialized_at` is null, returns boolean indicating whether seeding occurred

8. Revokes RPC execution from `PUBLIC` and `anon` and grants it to `authenticated`.

The migration recreates the policy, trigger and constraint. Use the recorded migration history and schema checks to avoid replaying an already-applied migration.

**Rollback complexity:** Disabling the RPC preserves existing rows. A backup restore can lose writes after the recovery point.

---

**Migration Plan Version:** 1.0  
**Last Updated:** 2026-11-15  
**Approved By:** [Pending Review]  
**Status:** Pending restore rehearsal, migration replay and production approval
