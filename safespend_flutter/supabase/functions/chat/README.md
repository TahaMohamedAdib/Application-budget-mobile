# SafeSpend AI Coach — Setup Guide

## Architecture

```
Flutter app  →  Supabase Edge Function  →  DeepSeek API
                (supabase/functions/chat)
```

The Edge Function lives inside your Supabase project — no separate server needed.

---

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- A DeepSeek API key → https://platform.deepseek.com
- Supabase project already linked (`supabase link --project-ref timctayytkcvxvpukvlq`)

---

## Step 1 — Set the DeepSeek secret

```bash
supabase secrets set DEEPSEEK_API_KEY=sk-your-key-here
```

Verify it was saved:
```bash
supabase secrets list
```

---

## Step 2 — Deploy the Edge Function

From the root of the Flutter project:

```bash
supabase functions deploy chat --no-verify-jwt
```

> `--no-verify-jwt` lets the function work even when a user is not authenticated
> (useful during testing). Remove this flag in production if you want to enforce auth.

---

## Step 3 — Grant beta access to test users

Open `lib/screens/coach_screen.dart` and edit the list at the top of the file:

```dart
const _allowedEmails = <String>[
  'your@email.com',
  'tester@email.com',
];
```

To open access to everyone:
```dart
const _openToAll = true;
```

---

## Step 4 — Rebuild the Flutter app

```bash
flutter build apk --debug
```

---

## Testing the Edge Function directly

```bash
curl -X POST \
  https://timctayytkcvxvpukvlq.supabase.co/functions/v1/chat \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_SUPABASE_ANON_KEY" \
  -d '{
    "messages": [{"role": "user", "content": "How am I doing financially?"}],
    "financial_context": {
      "currency": "USD",
      "net_worth": 12500,
      "bank_balance": 8000,
      "cash_on_hand": 500,
      "monthly_income": 3000,
      "this_month_income": 3000,
      "this_month_expenses": 2100,
      "top_categories": [
        {"name": "Food", "amount": 600},
        {"name": "Transport", "amount": 300}
      ],
      "goals": [],
      "debts": [],
      "personal_debts": []
    }
  }'
```

---

## Conversation flow

- The Flutter app keeps the full conversation history in memory (session only)
- Each message sends the entire history + the live financial snapshot to DeepSeek
- The AI has context of the whole conversation AND real financial data
- History is cleared when the user taps the refresh icon in the header

---

## Costs

| Service | Free tier | Paid |
|---------|-----------|------|
| Supabase Edge Functions | 500K invocations/month | $0.000002/invocation |
| DeepSeek `deepseek-chat` | — | ~$0.00014 per 1K input tokens |

A typical conversation message costs < $0.001.
