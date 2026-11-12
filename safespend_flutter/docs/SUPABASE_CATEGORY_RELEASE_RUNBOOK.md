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
6. `20261112000000_category_budget_inclusion.sql`

For an already current VVollet database, only step 6 is new. Take a managed
backup and record the migration history before beginning. The `ai_…sql` file
is not timestamped and is outside this release; do not include it merely
because it is in the directory.

## Pre-deployment checks

Run these in the target database and retain the output with the release:

```sql
select table_name, column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'user_categories'
order by ordinal_position;

select count(*) as categories_with_invalid_exclusion
from public.user_categories
where coalesce(include_in_monthly_budget, true) = false
  and coalesce(budget_limit, 0) <> 0;

select count(*) as existing_users from auth.users;
```

The invalid-exclusion count must be zero. Back up `auth.users`,
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

## Recovery

The migration is additive and preserves all existing categories and financial
rows. If deployment must be halted, revoke RPC execution from `authenticated`
and disable the trigger; do not drop the new column or marker table while
clients may have written to them. Restore from the pre-deployment backup only
under the established incident procedure. Once clients are rolled back,
investigate marker/category state before any manual repair; never re-run the
RPC for historical users because their markers intentionally prevent defaults
from returning.
