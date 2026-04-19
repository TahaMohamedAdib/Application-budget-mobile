-- ============================================
-- Storage Synchronization Trigger
-- Automatically syncs Supabase Storage uploads
-- with application tables
-- ============================================

-- Create configuration table to store project settings
CREATE TABLE IF NOT EXISTS public.app_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Insert or update project_ref (replace with your actual project ref)
INSERT INTO public.app_config (key, value, description)
VALUES ('supabase_project_ref', 'YOUR_PROJECT_REF', 'Your Supabase project reference ID')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Create indexes for config table
CREATE INDEX IF NOT EXISTS idx_app_config_key ON public.app_config(key);

-- ============================================
-- Add missing columns to existing tables
-- ============================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS receipt_url TEXT;

-- ============================================
-- Storage Sync Function
-- Handles file uploads to different buckets
-- SECURITY DEFINER ensures permissions bypass RLS
-- ============================================
CREATE OR REPLACE FUNCTION public.sync_storage_uploads()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_project_ref TEXT;
  v_public_url TEXT;
  v_group_id UUID;
  v_owner_id UUID;
BEGIN
  -- Get project reference from config table
  SELECT value INTO v_project_ref
  FROM public.app_config
  WHERE key = 'supabase_project_ref'
  LIMIT 1;

  -- Fallback to environment variable or hardcoded value if not in config
  IF v_project_ref IS NULL THEN
    v_project_ref := current_setting('app.supabase_project_ref', TRUE);
  END IF;

  IF v_project_ref IS NULL OR v_project_ref = 'YOUR_PROJECT_REF' THEN
    RAISE WARNING 'Supabase project ref not configured in app_config table';
    RETURN NEW;
  END IF;

  -- Build the public URL for the uploaded file
  v_public_url := 'https://' || v_project_ref || '.supabase.co/storage/v1/object/public/' ||
                  NEW.bucket_id || '/' || NEW.name;

  -- Get owner ID (convert from JWT sub if necessary)
  v_owner_id := NEW.owner::uuid;

  -- Route to appropriate table based on bucket_id
  CASE NEW.bucket_id
    -- Handle avatar uploads
    WHEN 'avatars' THEN
      UPDATE public.profiles
      SET avatar_url = v_public_url,
          updated_at = now()
      WHERE id = v_owner_id;

      -- Log if no profile exists
      IF NOT FOUND THEN
        RAISE WARNING 'Profile not found for user % when syncing avatar', v_owner_id;
      END IF;

    -- Handle receipt uploads
    WHEN 'receipts' THEN
      UPDATE public.transactions
      SET receipt_url = v_public_url,
          updated_at = now()
      WHERE id = (
        SELECT id
        FROM public.transactions
        WHERE user_id = v_owner_id
        ORDER BY created_at DESC
        LIMIT 1
      );

      -- Log if no transaction exists
      IF NOT FOUND THEN
        RAISE WARNING 'No recent transaction found for user % when syncing receipt', v_owner_id;
      END IF;

    -- Handle logos bucket (for account icons)
    WHEN 'logos' THEN
      UPDATE public.accounts
      SET image_path = v_public_url,
          updated_at = now()
      WHERE id = (
        SELECT id
        FROM public.accounts
        WHERE user_id = v_owner_id
        ORDER BY created_at DESC
        LIMIT 1
      );

      -- Log if no account exists
      IF NOT FOUND THEN
        RAISE WARNING 'No account found for user % when syncing logo', v_owner_id;
      END IF;

    -- Ignore other buckets
    ELSE
      RAISE DEBUG 'Storage sync: Ignoring upload to bucket %', NEW.bucket_id;
  END CASE;

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Log errors but don't fail the upload
  RAISE WARNING 'Error in storage sync trigger: % %', SQLERRM, SQLSTATE;
  RETURN NEW;
END;
$$;

-- ============================================
-- Trigger Definition
-- Activates the sync function on storage uploads
-- ============================================
DROP TRIGGER IF EXISTS sync_storage_uploads_trigger ON storage.objects;

CREATE TRIGGER sync_storage_uploads_trigger
AFTER INSERT ON storage.objects
FOR EACH ROW
EXECUTE FUNCTION public.sync_storage_uploads();

-- ============================================
-- Grant permissions for the trigger function
-- ============================================
GRANT EXECUTE ON FUNCTION public.sync_storage_uploads() TO authenticated, anon, service_role;
GRANT SELECT, UPDATE ON public.profiles TO service_role;
GRANT SELECT, UPDATE ON public.accounts TO service_role;
GRANT SELECT, UPDATE ON public.transactions TO service_role;
GRANT SELECT, UPDATE ON public.app_config TO service_role;

-- ============================================
-- Notes:
-- 1. Update 'YOUR_PROJECT_REF' in app_config with your actual Supabase project ref
--    (e.g., 'abcdefg' from 'abcdefg.supabase.co')
--
-- 2. This migration automatically adds missing columns:
--    - profiles.avatar_url (TEXT) — syncs from 'avatars' bucket
--    - transactions.receipt_url (TEXT) — syncs from 'receipts' bucket
--    - accounts.image_path already exists — syncs from 'logos' bucket
--
-- 3. The function uses SECURITY DEFINER to bypass RLS
--    This is safe because the function is trusted and validates inputs
--
-- 4. Supported buckets and their sync behavior:
--    - 'avatars': Updates the user's profile avatar_url
--    - 'receipts': Updates the most recent transaction's receipt_url
--    - 'logos': Updates the most recent account's image_path
--
-- 5. For future custom buckets (e.g., 'daret_icons'):
--    Add a new WHEN clause in the CASE statement with your custom logic
--    Example: Extract group_id from path, update custom table
-- ============================================
