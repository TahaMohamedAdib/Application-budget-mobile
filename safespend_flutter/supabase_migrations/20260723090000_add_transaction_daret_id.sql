-- Link financial transactions to the daret (ROSCA) contribution/payout they
-- belong to. Darets are persisted client-side (SharedPreferences) and have no
-- Postgres table, so this is a plain nullable UUID column WITHOUT a foreign key.
-- The client tolerates this column being absent until the migration is applied.
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS daret_id UUID;

CREATE INDEX IF NOT EXISTS idx_transactions_daret_id
  ON public.transactions(daret_id);
