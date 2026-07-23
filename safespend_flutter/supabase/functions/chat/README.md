# SafeSpend AI Proxy — Setup Guide

## Architecture

```text
Authenticated Flutter app
        |
        v
Supabase Edge Function: chat
        |
        v
Gemini gemini-2.5-flash :generateContent
```

The Flutter app sends the existing Gemini request payload through
`SupabaseClient.functions.invoke`. The Edge Function validates the signed-in
user with Supabase Auth, adds the server-side provider key, and relays Gemini's
status and response body unchanged.

The only accepted upstream target is:

- model: `gemini-2.5-flash`
- endpoint: `generateContent`

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- A Gemini API key
- The Supabase project linked:

```bash
supabase link --project-ref timctayytkcvxvpukvlq
```

## 1. Set the server-side secret

```bash
supabase secrets set GEMINI_API_KEY=your-key-here
```

Verify that the secret name is present:

```bash
supabase secrets list
```

Never add the key to Flutter `--dart-define` values or `.env.local`. The key
must exist only in Supabase Edge Function secrets.

## 2. Deploy the Edge Function

From the Flutter project root:

```bash
supabase functions deploy chat
```

Keep JWT verification enabled. The function also performs its own explicit
Supabase Auth user lookup and rejects missing, invalid, expired, and anon-only
credentials.

## 3. Build the Flutter app

The local `.env.local` file is still used for public Supabase configuration
and client feature flags. It must not contain `GEMINI_API_KEY`.

```powershell
.\scripts\build_debug_apk.ps1
```

`AI_ALLOWED_EMAILS` and `AI_OPEN_TO_ALL` control whether the client displays
the AI input. They are not a substitute for server authorization: even when
`AI_OPEN_TO_ALL=true`, the client requires a real Supabase session and the Edge
Function validates that session independently.

## Testing the function directly

Use a real signed-in user's access token, not the project anon key:

```bash
curl -X POST \
  https://timctayytkcvxvpukvlq.supabase.co/functions/v1/chat \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer A_REAL_USER_ACCESS_TOKEN" \
  -d '{
    "model": "gemini-2.5-flash",
    "endpoint": "generateContent",
    "body": {
      "contents": [
        {
          "role": "user",
          "parts": [{"text": "How am I doing financially?"}]
        }
      ],
      "generationConfig": {
        "temperature": 0.6,
        "maxOutputTokens": 1500,
        "topP": 0.9
      }
    }
  }'
```

Expected security checks:

- no `Authorization` header: `401`
- `Authorization: Bearer <anon key>`: `401`
- invalid or expired user token: `401`
- method other than `POST` or `OPTIONS`: `405`
- non-whitelisted model or endpoint: `400`
- missing `GEMINI_API_KEY` secret: `503`

## Request and response behavior

- Chat text, inline images, and inline PDFs retain their existing Gemini
  payload shapes.
- Transaction extraction retains its JSON response mode and parsing.
- The proxy does not translate provider errors. Gemini's HTTP status and body
  are returned to the client so the existing client-side error mapping remains
  effective.
- Conversation history remains in the Flutter app and is sent with each chat
  request.
