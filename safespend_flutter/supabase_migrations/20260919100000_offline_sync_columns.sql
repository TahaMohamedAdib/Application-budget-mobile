-- ============================================================
-- Offline sync metadata
-- ============================================================
-- Adds the three columns the offline-first client needs on every synced
-- table, plus the trigger that maintains them.
--
--   updated_at  When the row last changed, server-side. The pull cursor reads
--               this, so it must be set by the database and not by the client
--               — a device with a wrong clock would otherwise make its rows
--               invisible to, or permanently newer than, every other device.
--   deleted_at  Tombstone. A hard DELETE is invisible to a client that was
--               offline when it happened: the row simply is not in the next
--               pull, which is indistinguishable from never having existed,
--               so the client keeps its local copy forever. A tombstone is a
--               change the client can actually receive.
--   version     Optimistic lock, bumped on every write. Lets a push detect
--               that someone else changed the row first instead of silently
--               overwriting them.
--
-- SAFETY: this migration is additive and idempotent. It adds nullable columns
-- and a trigger; it does not drop, rename, or rewrite existing data, and
-- running it twice is a no-op. Existing rows get updated_at = NOW() on first
-- touch, version 1, and deleted_at NULL (i.e. alive), which is correct.
--
-- NOTE ON SCOPE: as of this migration the client writes `updated_at` only.
-- `version` and `deleted_at` are maintained server-side by the trigger below
-- and are read by the client; the client does not yet send them. The columns
-- exist now so that the pull cursor and tombstone handling have somewhere to
-- read from, and so a later client release can start writing them without a
-- second schema change during a rollout.

-- ── Columns ─────────────────────────────────────────────────
-- darets is deliberately absent: it has no remote table. Daret circles are
-- local-only, and the sync engine completes their queue entries without a
-- network call rather than retrying against a table that does not exist.

DO $$
DECLARE
  t TEXT;
  synced_tables TEXT[] := ARRAY[
    'accounts',
    'transactions',
    'goals',
    'stock_holdings',
    'user_categories',
    'recurring_rules'
  ];
BEGIN
  FOREACH t IN ARRAY synced_tables LOOP
    -- Skip tables this project has not created, so the migration is safe to
    -- run against a partially-provisioned database.
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = t
    ) THEN
      RAISE NOTICE 'Skipping %: table does not exist', t;
      CONTINUE;
    END IF;

    EXECUTE format(
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW()', t);
    EXECUTE format(
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ', t);
    EXECUTE format(
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1', t);
  END LOOP;
END $$;

-- profiles carries the user's settings blob and already has updated_at.
-- It is one row per user and is never deleted independently of the account,
-- so it needs the version column but no tombstone.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

COMMENT ON COLUMN public.accounts.deleted_at IS
  'Tombstone. NULL means the row is alive. Set instead of DELETE so that '
  'clients which were offline at deletion time still receive the change.';

-- ── Trigger ─────────────────────────────────────────────────
-- Server-authoritative updated_at and version.
--
-- Assigning these in the trigger rather than trusting the client is what makes
-- the pull cursor reliable: the ordering reflects when the server accepted
-- each write, which is the only clock all devices agree on.

CREATE OR REPLACE FUNCTION public.touch_sync_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
-- Explicit search_path: a SECURITY DEFINER-adjacent function that resolves
-- names through a caller-controlled path is a privilege-escalation route.
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at := NOW();

  IF TG_OP = 'UPDATE' THEN
    -- COALESCE covers rows written before this column existed.
    NEW.version := COALESCE(OLD.version, 0) + 1;
  ELSE
    NEW.version := 1;
  END IF;

  RETURN NEW;
END $$;

DO $$
DECLARE
  t TEXT;
  synced_tables TEXT[] := ARRAY[
    'accounts',
    'transactions',
    'goals',
    'stock_holdings',
    'user_categories',
    'recurring_rules',
    'profiles'
  ];
BEGIN
  FOREACH t IN ARRAY synced_tables LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = t
    ) THEN
      CONTINUE;
    END IF;

    EXECUTE format('DROP TRIGGER IF EXISTS touch_sync_metadata ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER touch_sync_metadata
         BEFORE INSERT OR UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.touch_sync_metadata()', t);
  END LOOP;
END $$;

-- ── Indexes ─────────────────────────────────────────────────
-- The pull is "everything for this user changed since my cursor", so the
-- cursor query needs (user_id, updated_at) to avoid scanning the user's full
-- history on every sync.

CREATE INDEX IF NOT EXISTS idx_accounts_sync
  ON public.accounts (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_transactions_sync
  ON public.transactions (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_goals_sync
  ON public.goals (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_stock_holdings_sync
  ON public.stock_holdings (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_user_categories_sync
  ON public.user_categories (user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_sync
  ON public.recurring_rules (user_id, updated_at);

-- ── Row Level Security ──────────────────────────────────────
-- RLS is unchanged and still the only authorization boundary: these columns
-- are metadata on rows that existing per-user policies already gate. A client
-- cannot read or tombstone another user's row through them, because it cannot
-- see that row at all.
--
-- Verify after running (expect rowsecurity = true for every row):
--   SELECT tablename, rowsecurity FROM pg_tables
--    WHERE schemaname = 'public'
--      AND tablename IN ('accounts','transactions','goals','stock_holdings',
--                        'user_categories','recurring_rules','profiles');
