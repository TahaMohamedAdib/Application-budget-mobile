-- Keep financial images private and authorize each object by its first
-- path segment: <bucket>/<auth.uid()>/<uuid>.jpg.

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES
  (
    'receipts',
    'receipts',
    false,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
  ),
  (
    'logos',
    'logos',
    false,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  )
ON CONFLICT (id) DO UPDATE
SET
  public = false,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Remove the former anonymous/public reads and replace every financial
-- bucket policy so rerunning this migration remains deterministic.
DROP POLICY IF EXISTS "Receipts public read" ON storage.objects;
DROP POLICY IF EXISTS "Receipts user upload" ON storage.objects;
DROP POLICY IF EXISTS "Receipts user update" ON storage.objects;
DROP POLICY IF EXISTS "Receipts user delete" ON storage.objects;
DROP POLICY IF EXISTS "Logos public read" ON storage.objects;
DROP POLICY IF EXISTS "Logos user upload" ON storage.objects;
DROP POLICY IF EXISTS "Logos user update" ON storage.objects;
DROP POLICY IF EXISTS "Logos user delete" ON storage.objects;

DROP POLICY IF EXISTS "Receipts owner select" ON storage.objects;
DROP POLICY IF EXISTS "Receipts owner insert" ON storage.objects;
DROP POLICY IF EXISTS "Receipts owner update" ON storage.objects;
DROP POLICY IF EXISTS "Receipts owner delete" ON storage.objects;
DROP POLICY IF EXISTS "Logos owner select" ON storage.objects;
DROP POLICY IF EXISTS "Logos owner insert" ON storage.objects;
DROP POLICY IF EXISTS "Logos owner update" ON storage.objects;
DROP POLICY IF EXISTS "Logos owner delete" ON storage.objects;

CREATE POLICY "Receipts owner select"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'receipts'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Receipts owner insert"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'receipts'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Receipts owner update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'receipts'
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'receipts'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Receipts owner delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'receipts'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Logos owner select"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'logos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Logos owner insert"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'logos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Logos owner update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'logos'
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'logos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Logos owner delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'logos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Financial records now store the exact object selected by the application.
-- The legacy trigger must therefore never guess a receipt/account from upload
-- order. Keep only its established avatar behavior.
CREATE OR REPLACE FUNCTION public.sync_storage_uploads()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_project_ref TEXT;
  v_public_url TEXT;
  v_owner_id UUID;
BEGIN
  IF NEW.bucket_id <> 'avatars' THEN
    RETURN NEW;
  END IF;

  SELECT value
  INTO v_project_ref
  FROM public.app_config
  WHERE key = 'supabase_project_ref'
  LIMIT 1;

  IF v_project_ref IS NULL THEN
    v_project_ref := current_setting('app.supabase_project_ref', TRUE);
  END IF;

  IF v_project_ref IS NULL OR v_project_ref = 'YOUR_PROJECT_REF' THEN
    RAISE WARNING 'Supabase project ref not configured in app_config table';
    RETURN NEW;
  END IF;

  IF NEW.owner IS NULL THEN
    RAISE WARNING 'Avatar upload % has no owner', NEW.name;
    RETURN NEW;
  END IF;

  v_owner_id := NEW.owner::uuid;
  v_public_url :=
    'https://' || v_project_ref ||
    '.supabase.co/storage/v1/object/public/avatars/' || NEW.name;

  UPDATE public.profiles
  SET
    avatar_url = v_public_url,
    updated_at = now()
  WHERE id = v_owner_id;

  IF NOT FOUND THEN
    RAISE WARNING
      'Profile not found for user % when syncing avatar',
      v_owner_id;
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error in storage sync trigger: % %', SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_storage_uploads_trigger ON storage.objects;

CREATE TRIGGER sync_storage_uploads_trigger
AFTER INSERT ON storage.objects
FOR EACH ROW
WHEN (NEW.bucket_id = 'avatars')
EXECUTE FUNCTION public.sync_storage_uploads();

GRANT EXECUTE
ON FUNCTION public.sync_storage_uploads()
TO authenticated, anon, service_role;
