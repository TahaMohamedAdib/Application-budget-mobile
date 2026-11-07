-- Durable state for the account-deletion Edge Function. The row is removed
-- automatically only after auth.users is successfully deleted, via CASCADE.
CREATE TABLE IF NOT EXISTS public.account_deletion_jobs (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('requested', 'storage_deleted', 'deleting_auth', 'failed')),
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.account_deletion_jobs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.account_deletion_jobs FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.touch_account_deletion_job()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS touch_account_deletion_job ON public.account_deletion_jobs;
CREATE TRIGGER touch_account_deletion_job
  BEFORE UPDATE ON public.account_deletion_jobs
  FOR EACH ROW EXECUTE FUNCTION public.touch_account_deletion_job();
