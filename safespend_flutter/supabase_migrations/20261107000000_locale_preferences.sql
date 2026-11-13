-- Sync language preference and its explicit-choice marker across a user's
-- devices. Existing rows default to automatic device-language selection.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS locale TEXT NOT NULL DEFAULT 'en',
  ADD COLUMN IF NOT EXISTS locale_manually_selected BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_locale_supported;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_locale_supported CHECK (
    locale IN ('en','fr','ar','es','de','pt','it','tr','nl','ru','zh','ja','ko','hi','id','pl')
  );
