import {
  extractBearerToken,
  isAllowedGeminiTarget,
  isAnonymousCredential,
} from './request_policy.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function isJsonObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

async function isValidSupabaseUser(
  token: string,
  supabaseUrl: string,
  supabaseAnonKey: string,
): Promise<boolean> {
  if (isAnonymousCredential(token, supabaseAnonKey)) return false

  try {
    const authResponse = await fetch(
      new URL('/auth/v1/user', supabaseUrl),
      {
        headers: {
          apikey: supabaseAnonKey,
          Authorization: `Bearer ${token}`,
        },
      },
    )
    if (!authResponse.ok) return false

    const user = await authResponse.json()
    return isJsonObject(user) && typeof user.id === 'string' && user.id !== ''
  } catch (error) {
    console.error('[chat] Supabase Auth validation failed', error)
    return false
  }
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        Allow: 'POST, OPTIONS',
      },
    })
  }

  const token = extractBearerToken(request.headers.get('Authorization'))
  if (token === null) {
    return jsonError('A valid user bearer token is required', 401)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')?.trim()
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')?.trim()
  if (!supabaseUrl || !supabaseAnonKey) {
    console.error('[chat] Supabase Auth configuration is missing')
    return jsonError('Authentication service is not configured', 503)
  }

  const hasValidUser = await isValidSupabaseUser(
    token,
    supabaseUrl,
    supabaseAnonKey,
  )
  if (!hasValidUser) {
    return jsonError('A valid user bearer token is required', 401)
  }

  let envelope: unknown
  try {
    envelope = await request.json()
  } catch {
    return jsonError('Request body must be valid JSON', 400)
  }

  if (!isJsonObject(envelope)) {
    return jsonError('Request body must be a JSON object', 400)
  }

  const { model, endpoint, body } = envelope
  if (!isAllowedGeminiTarget(model, endpoint)) {
    return jsonError('Requested AI model or endpoint is not allowed', 400)
  }
  if (!isJsonObject(body)) {
    return jsonError('AI request body must be a JSON object', 400)
  }

  const geminiApiKey = Deno.env.get('GEMINI_API_KEY')?.trim()
  if (!geminiApiKey) {
    console.error('[chat] GEMINI_API_KEY is not configured')
    return jsonError('AI service is not configured', 503)
  }

  const upstreamUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(model as string)}:${encodeURIComponent(endpoint as string)}`

  let upstreamResponse: Response
  try {
    upstreamResponse = await fetch(upstreamUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': geminiApiKey,
      },
      body: JSON.stringify(body),
    })
  } catch (error) {
    console.error('[chat] Gemini request failed', error)
    return jsonError('AI upstream request failed', 502)
  }

  const responseHeaders = new Headers(corsHeaders)
  responseHeaders.set(
    'Content-Type',
    upstreamResponse.headers.get('Content-Type') ?? 'application/json',
  )
  const retryAfter = upstreamResponse.headers.get('Retry-After')
  if (retryAfter !== null) responseHeaders.set('Retry-After', retryAfter)

  return new Response(upstreamResponse.body, {
    status: upstreamResponse.status,
    statusText: upstreamResponse.statusText,
    headers: responseHeaders,
  })
})
