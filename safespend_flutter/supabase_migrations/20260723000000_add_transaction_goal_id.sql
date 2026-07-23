-- Link financial transactions to the goal or debt they adjust.
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS goal_id UUID
  REFERENCES public.goals(id)
  ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_goal_id
  ON public.transactions(goal_id);
