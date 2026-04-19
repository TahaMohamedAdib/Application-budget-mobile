alter table if exists public.accounts
  add column if not exists added_at timestamptz default now();

update public.accounts
set added_at = coalesce(added_at, created_at, now())
where added_at is null;

alter table if exists public.stock_holdings
  add column if not exists source_account_id uuid,
  add column if not exists affects_source_balance boolean not null default false,
  add column if not exists source_amount numeric;
