# VVollet 1.0.1+3 Production Migration Plan

**Target:** Supabase production project `timctayytkcvxvpukvlq`  
**Migration:** Category budget inclusion (20261112000000) + dependencies  
**Prerequisites:** Staging validation complete, backup verified, maintenance window approved

---

## Pre-Flight Checklist

### 1. Staging Validation Complete

- [x] Gates GA–GF executed with documented evidence
- [x] Critical anon EXECUTE grant issue identified and remediation procedure validated
- [x] RLS policies verified
- [x] Concurrency guard tested
- [x] Exclusion constraint enforced
- [x] Backward compatibility confirmed (marker/trigger/defaults)
- [ ] Test gaps acknowledged and accepted as documented risks

### 2. Production Preparation

- [ ] Maintenance window scheduled and communicated to users
- [ ] Backup procedure tested in staging (see Backup Strategy below)
- [ ] Rollback procedure documented and validated
- [ ] On-call engineer identified for post-migration monitoring
- [ ] Incident response plan reviewed

### 3. Required Access

- [ ] Supabase CLI authenticated with production project access
- [ ] Production database credentials available (for backup verification)
- [ ] Admin access to Supabase dashboard (for manual verification)
- [ ] GitHub repository write access (for recording migration history)

---

## Migration Order

Apply these 8 timestamped migrations in exact order. Each has IF NOT EXISTS guards for idempotency:

1. `20260415000000_storage_sync_trigger.sql`
2. `20260415010000_add_account_tracking_and_holding_funding.sql`
3. `20260818000000_add_salary_pay_cycle.sql`
4. `20260919000000_profile_avatars.sql`
5. `20260919100000_offline_sync_columns.sql`
6. `20261107000000_locale_preferences.sql`
7. `20261107010000_account_deletion_jobs.sql`
8. `20261112000000_category_budget_inclusion.sql`

**Critical:** Verify which migrations are already present in the production schema before applying. Only apply missing migrations. The migration history check (Step 1 below) identifies which migrations to skip.

---

## Backup Strategy

### Before Migration

**Managed Backup (Recommended):**

```bash
# Via Supabase dashboard: Database → Backups → Create backup
# Label: "pre-category-budget-migration-20261115"
# Wait for backup to complete before proceeding
```

**Alternative: pg_dump Backup:**

```bash
PROD_REF="timctayytkcvxvpukvlq"
BACKUP_FILE="vvollet_prod_backup_$(date +%Y%m%d_%H%M%S).sql"

supabase db dump --project-ref "$PROD_REF" > "$BACKUP_FILE"

# Verify backup is not empty
test -s "$BACKUP_FILE" || { echo "Backup file is empty, aborting"; exit 1; }

# Compress and store securely
gzip "$BACKUP_FILE"
```

### Backup Restoration Test (Execute in Staging BEFORE Production)

```bash
STAGING_REF="dqhoqarozpgiuaqwxrcj"
test "$STAGING_REF" != "timctayytkcvxvpukvlq" || { echo "ABORT: wrong target"; exit 1; }

# Create a test backup
supabase db dump --project-ref "$STAGING_REF" > test_backup.sql

# Record pre-restore state
supabase db query --remote --read-only --project-ref "$STAGING_REF" \
  -f <(echo "select count(*) from auth.users;")

# Restore (THIS WILL OVERWRITE STAGING DATABASE)
# ONLY execute this step in a disposable staging environment
supabase db reset --project-ref "$STAGING_REF" --yes
psql "postgresql://postgres:[STAGING_PASSWORD]@db.$STAGING_REF.supabase.co:5432/postgres" \
  < test_backup.sql

# Verify post-restore state matches pre-restore
supabase db query --remote --read-only --project-ref "$STAGING_REF" \
  -f <(echo "select count(*) from auth.users;")

# Clean up
rm test_backup.sql
```

**Validation Criteria:**
- Backup file size > 0 bytes
- User count matches before and after restore
- All 7 base schema tables present after restore
- No connection errors during restore

**Result:** [ ] PASS  [ ] FAIL  
**Evidence:** (attach user count comparison and restore log output)

---

## Migration Procedure

### Step 1: Verify Migration History

**Purpose:** Identify which migrations are already applied to avoid re-running them.

```bash
PROD_REF="timctayytkcvxvpukvlq"

# Fail-closed safety check
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT: staging ref"; exit 1; }

# Check for migrations table or schema_migrations equivalent
supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<'EOF'
-- Option 1: If you have a schema_migrations table
select version from public.schema_migrations order by version;

-- Option 2: Check for column existence as migration markers
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'user_categories'
  and column_name in ('budget_limit', 'include_in_monthly_budget')
order by column_name;

-- Option 3: Check for marker table existence
select exists(
  select 1 from information_schema.tables
  where table_schema = 'public' and table_name = 'category_initialization'
) as category_initialization_exists;
EOF
)
```

**Expected Production State (as of 2026-11-15):**
- Migrations 1–7 likely already applied (account deletion and locale work)
- Migration 8 (category_budget_inclusion) **not yet applied**
- `budget_limit` column exists in `user_categories`
- `include_in_monthly_budget` column **does not exist** yet
- `category_initialization` table **does not exist** yet

**Action:** If migrations 1–7 are already recorded, **skip them**. Only apply migration 8.

---

### Step 2: Pre-Deployment Schema Verification

**Purpose:** Confirm baseline schema before migration 8 runs.

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<'EOF'
-- Verify user_categories baseline
select table_name, column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'user_categories'
order by ordinal_position;

-- Count existing users (for post-migration comparison)
select count(*) as existing_users from auth.users;

-- Verify no include_in_monthly_budget column exists yet (should return 0)
select count(*) as column_exists_check
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_categories'
  and column_name = 'include_in_monthly_budget';
EOF
) > pre_migration_state.log
```

**Save `pre_migration_state.log` with the release record.**

**Expected Results:**
- `budget_limit` column present with type `numeric`
- `include_in_monthly_budget` column **not present** (count = 0)
- Existing user count > 0

---

### Step 3: Apply Migration 8 (Category Budget Inclusion)

**Only execute if Step 1 confirmed migration 8 is not yet applied.**

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

# Navigate to repo root
cd D:/Work/Freelance/BudgetApp/safespend_flutter

# Apply migration 8
supabase db query --remote --yes --project-ref "$PROD_REF" \
  -f supabase_migrations/20261112000000_category_budget_inclusion.sql
```

**Expected Output:**
```
Target: project vvollet-production (timctayytkcvxvpukvlq) · production
Confirmed by --yes: Run a SQL statement on project vvollet-production...
{"rows": [], "boundary": "...", "warning": "..."}
```

**If errors occur:** STOP. Do not proceed to Step 4. Investigate the error, consult the rollback procedure, and escalate to incident response if needed.

---

### Step 4: Post-Migration Verification

**Purpose:** Confirm migration 8 applied correctly and all safety mechanisms are in place.

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<'EOF'
-- 1. Verify new column exists and has correct default
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_categories'
  and column_name = 'include_in_monthly_budget';

-- 2. Verify all existing rows have include_in_monthly_budget = true
select count(*) as rows_with_null_inclusion
from public.user_categories
where include_in_monthly_budget is null;

-- 3. Verify marker table exists and has RLS enabled
select tablename, rowsecurity as rls_enabled
from pg_tables
where schemaname = 'public' and tablename = 'category_initialization';

-- 4. Verify marker table has exactly one policy (SELECT-only)
select count(*) as policy_count
from pg_policies
where schemaname = 'public' and tablename = 'category_initialization';

-- 5. Verify auth trigger is installed and enabled
select tgname, tgenabled
from pg_trigger
where tgrelid = 'auth.users'::regclass
  and tgname = 'on_auth_user_category_marker';

-- 6. Verify all pre-existing users have initialized_at backfilled
select count(*) as users_with_marker
from public.category_initialization;

select count(*) as total_users from auth.users;

-- 7. Verify exclusion constraint exists
select conname, pg_get_constraintdef(oid) as constraint_def
from pg_constraint
where conrelid = 'public.user_categories'::regclass
  and conname = 'user_categories_excluded_budget_limit';

-- 8. Verify RPC function exists
select proname, prosecdef as security_definer
from pg_proc
where oid = 'public.initialize_default_categories(jsonb)'::regprocedure;
EOF
) > post_migration_verification.log
```

**Save `post_migration_verification.log` with the release record.**

**Expected Results:**
- `include_in_monthly_budget` column exists with type `boolean`, default `true`
- Zero rows with null `include_in_monthly_budget`
- `category_initialization` table exists with `relrowsecurity = true`
- Exactly 1 policy on `category_initialization` (SELECT-only)
- Trigger `on_auth_user_category_marker` exists with `tgenabled = 'O'`
- Marker count equals total user count (all backfilled)
- Constraint `user_categories_excluded_budget_limit` exists with correct definition
- RPC `initialize_default_categories` exists with `prosecdef = true`

**If any check fails:** STOP. Consult rollback procedure.

---

### Step 5: Critical Security Fix (Anon Grant)

**Purpose:** Immediately revoke unexpected anon EXECUTE grant discovered in staging validation.

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

# Check current grants
supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<'EOF'
select has_function_privilege('anon', 'public.initialize_default_categories(jsonb)'::regprocedure, 'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated', 'public.initialize_default_categories(jsonb)'::regprocedure, 'EXECUTE') as authenticated_can_execute,
       proacl
from pg_proc
where oid = 'public.initialize_default_categories(jsonb)'::regprocedure;
EOF
)

# If anon_can_execute is TRUE, revoke immediately
supabase db query --remote --yes --project-ref "$PROD_REF" -f <(cat <<'EOF'
REVOKE EXECUTE ON FUNCTION public.initialize_default_categories(jsonb) FROM anon;
EOF
)

# Re-verify grants after revoke
supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<'EOF'
select has_function_privilege('anon', 'public.initialize_default_categories(jsonb)'::regprocedure, 'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated', 'public.initialize_default_categories(jsonb)'::regprocedure, 'EXECUTE') as authenticated_can_execute
from pg_proc
where oid = 'public.initialize_default_categories(jsonb)'::regprocedure;
EOF
) > anon_grant_fix_verification.log
```

**Expected Final State:**
- `anon_can_execute = FALSE`
- `authenticated_can_execute = TRUE`

**Save `anon_grant_fix_verification.log` with the release record.**

---

### Step 6: Smoke Test

**Purpose:** Verify the RPC works correctly for a new test user in production.

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

# Create a disposable test user via Supabase dashboard or admin API
# Email: production-smoke-test@example.com (use a real domain you control)

# Record the test user's UUID
TEST_USER_UUID="<insert-uuid-here>"

# Call the RPC as the test user (via authenticated client or admin impersonation)
# Expected: Returns true, creates marker row, inserts 1 category

# Verify marker row created
supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<EOF
select initialized_at from public.category_initialization
where user_id = '$TEST_USER_UUID';
EOF
)

# Verify category row created
supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<EOF
select count(*) as category_count from public.user_categories
where user_id = '$TEST_USER_UUID';
EOF
)

# Call RPC again as the same user
# Expected: Returns false (already initialized)

# Clean up test user
# Delete via Supabase dashboard: Authentication → Users → [test user] → Delete
```

**Expected Results:**
- First RPC call returns `true`
- Marker row exists with non-null `initialized_at`
- Category count matches payload (typically 1 for minimal test)
- Second RPC call returns `false`

**If smoke test fails:** Escalate immediately. Do not release to real users.

---

### Step 7: Record Migration History

**Purpose:** Document the migration in the repository for future reference.

```bash
# Update migration tracking file or CHANGELOG
# Example:

cat >> docs/MIGRATION_HISTORY.md <<EOF

## 2026-11-15 — Category Budget Inclusion (1.0.1+3)

**Applied migrations:**
- 20261112000000_category_budget_inclusion.sql

**Verification logs:**
- pre_migration_state.log
- post_migration_verification.log
- anon_grant_fix_verification.log

**Notes:**
- Revoked unexpected anon EXECUTE grant on initialize_default_categories RPC
- All pre-existing users backfilled with initialized_at marker
- Smoke test passed with test user $TEST_USER_UUID

**Signed off by:** [Your Name]
**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
EOF

# Commit migration history
git add docs/MIGRATION_HISTORY.md
git add docs/SUPABASE_PRODUCTION_MIGRATION_PLAN.md
git add docs/SUPABASE_STAGING_VALIDATION_RESULTS.md
git commit -m "docs: record 1.0.1+3 production migration (category budget inclusion)

Applied migration 20261112000000_category_budget_inclusion.sql to production.
Verified marker backfill, RLS policies, and exclusion constraint.
Revoked unexpected anon EXECUTE grant on initialize_default_categories RPC.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Post-Deployment Monitoring

### First 24 Hours

Monitor these metrics and logs:

1. **RPC call success rate:**
   ```sql
   -- Run hourly for first 24 hours
   select count(*) as rpc_calls_last_hour
   from public.category_initialization
   where created_at > now() - interval '1 hour';
   ```

2. **User-reported issues:**
   - Watch support channels for reports of missing categories, budget errors, or login failures
   - Check error tracking (Sentry, Rollbar, etc.) for new exceptions related to categories or RPC calls

3. **Database errors:**
   ```sql
   -- Check for constraint violations
   select count(*) as exclusion_violations_last_24h
   from pg_stat_statements
   where query like '%user_categories_excluded_budget_limit%'
     and calls > 0
     and created > now() - interval '24 hours';
   ```

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

### Option 1: Disable RPC and Trigger (Non-Destructive)

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

# Revoke RPC execution from authenticated users
supabase db query --remote --yes --project-ref "$PROD_REF" -f <(cat <<'EOF'
REVOKE EXECUTE ON FUNCTION public.initialize_default_categories(jsonb) FROM authenticated;
EOF
)

# Disable the auth trigger
supabase db query --remote --yes --project-ref "$PROD_REF" -f <(cat <<'EOF'
ALTER TABLE auth.users DISABLE TRIGGER on_auth_user_category_marker;
EOF
)
```

**Effect:** New users will not get default categories. Existing users unaffected. Clients referencing the new column will see `include_in_monthly_budget = true` for all rows (default). No data loss.

**When to use:** First-line rollback for RPC-related issues (authorization failures, duplicate seeding, marker corruption).

### Option 2: Restore from Backup (Destructive)

**ONLY use this option under the established incident response procedure. Data written after the backup will be lost.**

```bash
PROD_REF="timctayytkcvxvpukvlq"
test "$PROD_REF" != "dqhoqarozpgiuaqwxrcj" || { echo "ABORT"; exit 1; }

# Via Supabase dashboard: Database → Backups → [pre-migration backup] → Restore
# This will overwrite the production database with the backup state

# After restore, verify:
supabase db query --remote --read-only --project-ref "$PROD_REF" -f <(cat <<'EOF'
select count(*) as user_count from auth.users;

select exists(
  select 1 from information_schema.columns
  where table_schema = 'public'
    and table_name = 'user_categories'
    and column_name = 'include_in_monthly_budget'
) as migration_rolled_back;
EOF
)
```

**Expected Post-Restore State:**
- User count matches pre-migration count (from backup)
- `include_in_monthly_budget` column does NOT exist (rolled back)
- `category_initialization` table does NOT exist (rolled back)

**Data Loss Window:** All data written between backup and restore is lost. Communicate downtime to users.

### Option 3: Manual Repair (Corruption Recovery)

If specific data corruption is detected (e.g., duplicate categories for a subset of users), repair selectively rather than full restore:

```sql
-- Example: Remove duplicate categories for affected users
delete from public.user_categories
where id in (
  select id from (
    select id, row_number() over (partition by user_id, category_id order by created_at) as rn
    from public.user_categories
  ) t
  where rn > 1
);
```

**Only execute manual repairs after:**
1. Root cause analysis identifies the corruption pattern
2. Repair SQL tested in staging with synthetic duplicates
3. Incident commander approves the repair

---

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
3. Creates table `public.category_initialization` with columns `user_id`, `initialized_at`, `created_at`, `updated_at`
4. Enables RLS on `category_initialization` with SELECT-only policy `auth.uid() = user_id`
5. Backfills `category_initialization` with all existing `auth.users` (sets `initialized_at = now()` for all)
6. Creates trigger `on_auth_user_category_marker` on `auth.users` (AFTER INSERT) to auto-insert marker rows for new signups
7. Creates function `public.initialize_default_categories(jsonb)` with SECURITY DEFINER, uses `auth.uid()`, locks marker row with `FOR UPDATE`, inserts categories only if `initialized_at` is null, returns boolean indicating whether seeding occurred

**Idempotency:** All operations use `IF NOT EXISTS` or `OR REPLACE`. Re-running the migration is safe (will no-op if already applied).

**Rollback complexity:** Low for Option 1 (disable RPC/trigger), High for Option 2 (backup restore with data loss).

---

**Migration Plan Version:** 1.0  
**Last Updated:** 2026-11-15  
**Approved By:** [Pending Review]  
**Status:** Ready for production deployment after backup/restore validation in staging
