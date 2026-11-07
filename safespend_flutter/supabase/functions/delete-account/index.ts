// Deletes the calling user's account: their stored photos, then the auth user.
//
// Every user table references auth.users with ON DELETE CASCADE, so removing
// the auth user removes all of their database rows. Storage objects are not
// covered by those cascades and are removed explicitly first.
//
// Required by App Store guideline 5.1.1(v) and Google Play's account deletion
// policy: users must be able to delete their account from inside the app.
//
// The caller is identified only from their own JWT; the request body is
// ignored, so nobody can delete another person's account.

import { createClient } from 'npm:@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

/// Buckets whose objects live under a `<user id>/` folder.
const USER_BUCKETS = ['receipts', 'avatars', 'logos']

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'X-Content-Type-Options': 'nosniff',
    },
  })
}

type Admin = ReturnType<typeof createClient>

/// Lists every object path under [prefix], descending into sub-folders.
async function listAll(admin: Admin, bucket: string, prefix: string): Promise<string[]> {
  const paths: string[] = []
  const pageSize = 1000
  for (let offset = 0; ; offset += pageSize) {
    const { data, error } = await admin.storage
      .from(bucket)
      .list(prefix, { limit: pageSize, offset })
    if (error) throw error
    if (!data || data.length === 0) break
    for (const entry of data) {
      const path = `${prefix}/${entry.name}`
      // Folders come back without an id.
      if (entry.id === null) {
        paths.push(...(await listAll(admin, bucket, path)))
      } else {
        paths.push(path)
      }
    }
    if (data.length < pageSize) break
  }
  return paths
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ error: 'server_misconfigured' }, 500)
  }

  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) return json({ error: 'unauthorized' }, 401)

  // Resolve the caller from their own token.
  const asUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  })
  const { data: userData, error: userError } = await asUser.auth.getUser()
  const userId = userData?.user?.id
  if (userError || !userId) return json({ error: 'unauthorized' }, 401)

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  })

  try {
    for (const bucket of USER_BUCKETS) {
      const paths = await listAll(admin, bucket, userId)
      for (let i = 0; i < paths.length; i += 100) {
        const { error } = await admin.storage.from(bucket).remove(paths.slice(i, i + 100))
        if (error) throw error
      }
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId)
    if (deleteError) throw deleteError
  } catch (e) {
    console.error('[delete-account] failed for', userId, e)
    return json({ error: 'delete_failed' }, 500)
  }

  return json({ deleted: true })
})
