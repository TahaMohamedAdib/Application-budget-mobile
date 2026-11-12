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

create or replace function public.initialize_default_categories(p_categories jsonb)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_user uuid := auth.uid(); v_marker public.category_initialization%rowtype;
begin
  if v_user is null then raise exception 'authentication required'; end if;
  select * into v_marker from public.category_initialization where user_id = v_user for update;
  if not found or v_marker.initialized_at is not null then return false; end if;
  insert into public.user_categories(user_id, category_id, group_name, name, icon, color, budget_limit, include_in_monthly_budget)
  select v_user, x->>'id', x->>'group', x->>'name', x->>'icon', x->>'color', coalesce((x->>'budgetLimit')::numeric, 0), coalesce((x->>'includeInMonthlyBudget')::boolean, true)
  from jsonb_array_elements(p_categories) x
  on conflict (user_id, category_id) do nothing;
  update public.category_initialization set initialized_at = now() where user_id = v_user;
  return true;
end $$;
revoke all on function public.initialize_default_categories(jsonb) from public;
grant execute on function public.initialize_default_categories(jsonb) to authenticated;
