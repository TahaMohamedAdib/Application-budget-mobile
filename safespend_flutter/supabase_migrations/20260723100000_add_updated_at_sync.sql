-- Sync conflict detection (T5): ensure every synchronized table carries an
-- updated_at column and a BEFORE UPDATE trigger that refreshes it. The client
-- compares its local updated_at against the remote value and applies
-- last-write-wins (see lib/services/sync_conflict.dart).
--
-- Idempotent: safe to run repeatedly.

-- Shared trigger function: stamp updated_at = now() on every UPDATE.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t TEXT;
  synced_tables TEXT[] := ARRAY[
    'profiles',
    'accounts',
    'transactions',
    'goals',
    'recurring_rules',
    'stock_holdings',
    'user_categories',
    'ai_conversations',
    'ai_projects'
  ];
BEGIN
  FOREACH t IN ARRAY synced_tables LOOP
    -- Skip tables that do not exist in this environment.
    IF to_regclass('public.' || t) IS NULL THEN
      RAISE NOTICE 'Skipping %: table does not exist', t;
      CONTINUE;
    END IF;

    -- Add the column if missing.
    EXECUTE format(
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now()',
      t
    );

    -- Recreate the trigger deterministically.
    EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at_trigger ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER set_updated_at_trigger BEFORE UPDATE ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()',
      t
    );
  END LOOP;
END;
$$;
