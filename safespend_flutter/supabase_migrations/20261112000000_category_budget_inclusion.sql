-- Additive only. Review and apply through the Supabase SQL editor after approval.
alter table public.user_categories
  add column if not exists include_in_monthly_budget boolean not null default true;

alter table public.user_categories
  drop constraint if exists user_categories_excluded_budget_limit;
alter table public.user_categories
  add constraint user_categories_excluded_budget_limit
  check (include_in_monthly_budget or budget_limit = 0);

-- Existing users are deliberately marked initialized: an empty historical
-- category list must never cause defaults to reappear.
create table if not exists public.category_initialization (
  user_id uuid primary key references auth.users(id) on delete cascade,
  initialized_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.category_initialization enable row level security;
create policy "users read own category initialization" on public.category_initialization for select using (auth.uid() = user_id);
insert into public.category_initialization (user_id, initialized_at)
select id, now() from auth.users on conflict (user_id) do nothing;

-- New accounts receive a marker only; client calls the idempotent RPC after
-- authentication, so offline devices cannot manufacture duplicate defaults.
create or replace function public.mark_new_category_account()
returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.category_initialization(user_id) values (new.id) on conflict do nothing; return new; end $$;
drop trigger if exists on_auth_user_category_marker on auth.users;
create trigger on_auth_user_category_marker after insert on auth.users for each row execute function public.mark_new_category_account();
