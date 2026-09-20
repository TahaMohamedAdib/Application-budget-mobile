-- ============================================================
-- Profile pictures
-- ============================================================
-- Adds the avatars bucket, its owner-scoped policies, and the profile column
-- that references an uploaded picture.
--
-- Storage columns hold an object PATH ("{user_id}/avatar.jpg"), never a URL.
-- These buckets are private, so any URL is short-lived; persisting one leaves
-- the image broken an hour later and permanently broken after a reinstall.
-- The client re-signs the path on demand.

-- The legacy storage trigger writes public URLs and guesses which row an
-- upload belongs to. The app now writes the exact object path to the exact
-- profile itself, so leaving that trigger active can race the client and
-- persist an unusable URL for this private bucket.
DROP TRIGGER IF EXISTS sync_storage_uploads_trigger ON storage.objects;

-- ── Column ──────────────────────────────────────────────────
-- A prior migration may already have added this; keep it idempotent.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN public.profiles.avatar_url IS
  'Storage object path in the avatars bucket, e.g. "{user_id}/avatar.jpg". '
  'Not a URL: the bucket is private and links are signed on demand.';

-- ── Bucket ──────────────────────────────────────────────────
-- Private, like receipts and logos. A profile picture identifies a person, so
-- it should not be readable by anyone who guesses the URL.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  false,
  5242880, -- 5 MB; images are compressed client-side well below this
  ARRAY['image/jpeg','image/png','image/webp','image/heic']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ── Policies ────────────────────────────────────────────────
-- Every verb is scoped to the uploader: the first path segment must equal the
-- caller's user id. Uploads are written server-side as "{uid}/avatar.jpg", so
-- a crafted filename cannot place an object in another user's folder.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='objects' AND schemaname='storage'
      AND policyname='Avatars owner read'
  ) THEN
    CREATE POLICY "Avatars owner read" ON storage.objects FOR SELECT
      USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='objects' AND schemaname='storage'
      AND policyname='Avatars owner upload'
  ) THEN
    CREATE POLICY "Avatars owner upload" ON storage.objects FOR INSERT
      WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='objects' AND schemaname='storage'
      AND policyname='Avatars owner update'
  ) THEN
    -- Needed because the client uploads with upsert: replacing a picture is
    -- an UPDATE on an existing object.
    CREATE POLICY "Avatars owner update" ON storage.objects FOR UPDATE
      USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1])
      WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='objects' AND schemaname='storage'
      AND policyname='Avatars owner delete'
  ) THEN
    CREATE POLICY "Avatars owner delete" ON storage.objects FOR DELETE
      USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
  END IF;
END $$;

-- ── Cleanup on account deletion ─────────────────────────────
-- profiles.id cascades from auth.users, so the row disappears with the
-- account. Storage objects do not cascade; removing them is handled by the
-- app's delete-account flow.
