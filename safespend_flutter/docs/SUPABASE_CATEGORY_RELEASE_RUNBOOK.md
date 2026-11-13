# Category budget and default-seeding migration runbook

Do not run this procedure against production without an approved maintenance
window and a verified database backup. This document applies only to an
authorized Supabase staging or production project.

## Migration order

Apply timestamped migrations in this order if they are not already recorded by
the target project's migration history:

1. `20260415000000_storage_sync_trigger.sql`
2. `20260415010000_add_account_tracking_and_holding_funding.sql`
3. `20260818000000_add_salary_pay_cycle.sql`
4. `20260919000000_profile_avatars.sql`
5. `20260919100000_offline_sync_columns.sql`
6. `20261107000000_locale_preferences.sql`
7. `20261107010000_account_deletion_jobs.sql`
8. `20261112000000_category_budget_inclusion.sql`

Only the migrations absent from the target project's recorded history are
applied. For a database already carrying the account-deletion work, steps 1–7
are recorded and only step 8 is new. Confirm which of steps 6 and 7 the target
project has actually recorded before assuming either is present: the
account-deletion edge function and the locale-preference sync both depend on
them, so an unrecorded step is a missing dependency, not a skipped one. Take a
managed backup and record the migration history before beginning. The `ai_…sql`
file is not timestamped and is outside this release; do not include it merely
because it is in the directory.

## Pre-deployment checks

Run these in the target database and retain the output with the release:

```sql
select table_name, column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_categories'
order by ordinal_position;

select count(*) as existing_users from auth.users;
```

The first query must show the existing `budget_limit` column. It intentionally
does **not** reference `include_in_monthly_budget`, because that column does
not exist until this migration runs. Back up `auth.users`,
`public.user_categories`, and any existing migration-history table before
applying the migration.

## Staging validation

Create two disposable authenticated staging users. Configure the app's
staging Supabase URL and anon key, then validate through the client and with
two independent authenticated sessions:

1. A new user starts with an uninitialized marker, calls the RPC once, and
   receives the expected categories exactly once.
2. Start both calls at the same time from separate sessions. One returns
   `true`, one returns `false`; category rows have no duplicates.
3. Delete one seeded category, call the RPC again, and verify it is not
   recreated.
4. Create an existing-user fixture before applying the migration. After the
   migration it has a non-null `initialized_at`; calling the RPC returns
   `false` even when that user has no categories.
5. Confirm that a category with `include_in_monthly_budget = false` has a
   zero budget limit, while its transactions still appear in normal expense
   reporting and account balances.

Useful verification SQL (substitute the disposable user UUID):

```sql
select category_id, budget_limit, include_in_monthly_budget
from public.user_categories
where user_id = '<user-uuid>'
order by category_id;

select user_id, initialized_at
from public.category_initialization
where user_id = '<user-uuid>';

select user_id, category_id, count(*)
from public.user_categories
group by user_id, category_id
having count(*) > 1;

select conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.user_categories'::regclass
  and conname = 'user_categories_excluded_budget_limit';

select count(*) as categories_with_invalid_exclusion
from public.user_categories
where include_in_monthly_budget = false
  and coalesce(budget_limit, 0) <> 0;

select p.proname, p.prosecdef, p.proconfig,
       has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute
from pg_proc p
where p.oid = 'public.initialize_default_categories(jsonb)'::regprocedure;
```

Expected RPC security results: `prosecdef` is true, `proconfig` contains
`search_path=public`, `anon_can_execute` is false, and
`authenticated_can_execute` is true. The RPC has no user-id argument and
uses `auth.uid()`; an unauthenticated invocation must raise `authentication
required`. Inspect the marker table's RLS policy as well:

```sql
select policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'category_initialization';
```

## Staging validation procedure for 1.0.1+2

Run every gate below against a disposable staging project before requesting the
production window. A gate passes only when its expected result is observed; a
gate that was not exercised is recorded as NOT TESTED, never as PASS.

### Prerequisites

Create three disposable users in the staging project before starting:

- **A** and **B** — ordinary authenticated users, created after the migration.
- **C** — a pre-migration fixture. Create C, give it at least one category row
  with a non-zero `budget_limit`, then apply the migration. This user is the
  backward-compatibility case and must not be recreated afterwards.

Build the client against staging only — never against the production URL:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=<staging-url> \
  --dart-define=SUPABASE_ANON_KEY=<staging-anon-key> \
  --dart-define=SUPABASE_AUTH_CALLBACK=io.supabase.<staging-ref>://login-callback/
```

The callback scheme embeds the project ref, so a staging build needs its own
`key.properties`-independent scheme registered in the staging project's Auth
redirect allow-list and in the manifest of the staging build. A build that keeps
the production scheme will hand the recovery token to the production project.

### GA — Authenticated concurrency

1. Sign in as A on two independent sessions (two devices, or one device plus a
   `curl` session using A's access token).
2. Fire `initialize_default_categories` from both at the same time. From the
   shell, start both requests in the background so neither finishes before the
   other starts:

```bash
for i in 1 2; do
  curl -s -o /tmp/seed-$i.json -w '%{http_code}\n' \
    -X POST "$STAGING_URL/rest/v1/rpc/initialize_default_categories" \
    -H "apikey: $STAGING_ANON_KEY" \
    -H "Authorization: Bearer $USER_A_ACCESS_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"p_categories":[{"id":"c1","group":"variable","name":"Test","icon":"category","color":"#22c55e","budgetLimit":10,"includeInMonthlyBudget":true}]}' &
done
wait
cat /tmp/seed-1.json /tmp/seed-2.json
```

Expected: both responses are HTTP 200, exactly one body is `true` and one is
`false`. A result of `true` twice means the `for update` lock on the marker row
is not serialising the calls — FAIL, stop and investigate before proceeding.

3. Both calls use the same payload, so the row count is determined by the
   payload, not by the number of calls. Retry the same script with a
   two-category payload and confirm exactly two rows exist, no more.
4. Confirm no duplicate rows and that `initialized_at` was written once:

```sql
select category_id, count(*)
from public.user_categories
where user_id = '<user-a-uuid>'
group by category_id
having count(*) > 1;

select user_id, initialized_at, created_at
from public.category_initialization
where user_id = '<user-a-uuid>';
```

Both queries must return the expected single row each, and the duplicate query
must return no rows.

### GB — RLS and authorization

1. Call the RPC with the anon key and no `Authorization` header. Expected: a
   non-2xx response, never `true`. The function raises `authentication required`
   when `auth.uid()` is null, and `anon` holds no execute grant.
2. Re-run the `pg_proc` / `has_function_privilege` query from the section above
   and confirm `prosecdef` is true, `proconfig` contains `search_path=public`,
   `anon_can_execute` is false, and `authenticated_can_execute` is true.
3. Confirm the RPC exposes no user-id parameter, so a caller cannot seed rows
   into another account:

```sql
select pg_get_function_arguments(
  'public.initialize_default_categories(jsonb)'::regprocedure);
```

Expected: `p_categories jsonb` only.

4. Confirm the marker table accepts exactly one policy and that it is
   select-only for the row's owner:

```sql
select policyname, cmd, qual
from pg_policies
where schemaname = 'public' and tablename = 'category_initialization';
```

Any INSERT, UPDATE, or DELETE policy on this table widens the seeding contract
and must be treated as a FAIL until reviewed.

5. As A, attempt an insert/update/delete on `category_initialization`. Expected:
   permission denied or zero rows affected. If an authenticated client can write
   its own marker it can clear `initialized_at` and re-seed defaults.

### GC — Ownership

1. Sign in as A, then attempt to read, update, and delete B's rows in
   `public.user_categories` using both the client and REST calls scoped with
   `.eq('user_id', '<user-b-uuid>')`. Expected: no rows returned, and no row
   changed or removed.
2. Run the same three operations as B against A's rows. Expected: the same
   rejection in the opposite direction, which rules out a session mix-up.
3. Confirm the RPC wrote only rows owned by the caller:

```sql
select user_id, count(*)
from public.user_categories
where user_id in ('<user-a-uuid>', '<user-b-uuid>')
group by user_id;
```

Every row produced by A's seeding carries A's id, and B's count is unchanged by
A's calls.
4. Confirm `public.user_categories` still has RLS enabled:

```sql
select relname, relrowsecurity, relforcerowsecurity
from pg_class where oid = 'public.user_categories'::regclass;
```

### GD — Category-deletion persistence

1. As A, delete one seeded category in the app and wait for the delete to reach
   the server. Confirm the row is gone server-side.
2. Call the RPC again as A. Expected: `false`, and the deleted category does not
   reappear while A's other rows are untouched.
3. Repeat the deletion while the device is offline: delete, confirm the pending
   sync indicator, reconnect, and wait for the queue to drain. The server-side
   row must disappear and a later RPC call must still return `false`.
4. Sign in as A on the second device and let it complete a sync cycle. The
   deleted category must not be recreated there either — a stale local copy that
   upserts back to `user_categories` would silently undo the deletion.
5. Do not "repair" a reappearing category by re-running the RPC. A re-run cannot
   help, because the marker already prevents seeding; a reappearing row is a sync
   bug to investigate.

### GE — Backward compatibility

1. User C (created before the migration): `initialized_at` is non-null and
   `created_at` is earlier than the migration run. Calling the RPC as C returns
   `false` even though C may have no categories at all.
2. Every pre-existing category row kept its `budget_limit` value and now carries
   `include_in_monthly_budget = true`:

```sql
select count(*) as rows_missing_inclusion_flag
from public.user_categories
where include_in_monthly_budget is null;
```

Expected: `0`.
3. The exclusion constraint accepts legitimate rows and rejects an excluded row
   with a non-zero limit:

```sql
-- expect an error, not a successful update
update public.user_categories
set include_in_monthly_budget = false, budget_limit = 500
where user_id = '<user-c-uuid>';
```

Roll the statement back or discard the fixture afterwards; it is a negative test.
4. Confirm the auth trigger is installed, so accounts created after the
   migration cannot reach the RPC without a marker:

```sql
select tgname, tgenabled
from pg_trigger
where tgrelid = 'auth.users'::regclass
  and tgname = 'on_auth_user_category_marker';
```

5. Install the currently published 1.0.0 client build against the migrated
   staging project, sign in as C, and open the budgets screen. Categories must
   load and normal editing must keep working: the new column is additive and its
   default keeps older clients valid. Record the tested build number with the
   result.

### Recording the result

For each gate, record the gate id, the observed output, the staging project ref,
and the date. Attach the `select` outputs to the release record. Any FAIL
blocks the production request; any gate not exercised is reported as NOT TESTED.

## Recovery

The migration is additive and preserves all existing categories and financial
rows. If deployment must be halted, revoke RPC execution from `authenticated`
and disable the trigger; do not drop the new column or marker table while
clients may have written to them. Restore from the pre-deployment backup only
under the established incident procedure. Once clients are rolled back,
investigate marker/category state before any manual repair; never re-run the
RPC for historical users because their markers intentionally prevent defaults
from returning.
