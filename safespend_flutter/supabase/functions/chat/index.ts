// Every call to this function spends money — DeepSeek bills per token — so it
// is treated as a privileged endpoint: authenticated, origin-restricted,
// size-capped, schema-validated and rate-limited.
//
// It previously accepted anonymous requests from any origin with `*` CORS,
// which let anyone who found the URL drain the API key indefinitely.

const DEEPSEEK_API_KEY = Deno.env.get('DEEPSEEK_API_KEY') ?? ''
const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

/// Browser origins allowed to call this function, comma-separated. Native
/// mobile clients send no Origin header and are unaffected. Empty by default:
/// deny by default rather than the previous wildcard.
const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
  .split(',')
  .map((o) => o.trim())
  .filter((o) => o.length > 0)

/// Hard ceilings. Without these one caller can push an arbitrarily large
/// prompt and bill the key for it.
const MAX_BODY_BYTES = 128 * 1024
const MAX_MESSAGES = 40
const MAX_MESSAGE_CHARS = 8000

/// Per-user sliding window. In-memory, so it is per-isolate rather than
/// global: a speed bump against runaway clients, not a billing guarantee.
/// Durable limits belong in the database or an API gateway.
const RATE_LIMIT_MAX = 20
const RATE_LIMIT_WINDOW_MS = 60_000
const rateBuckets = new Map<string, number[]>()

function rateLimited(userId: string): boolean {
  const now = Date.now()
  const hits = (rateBuckets.get(userId) ?? []).filter(
    (t) => now - t < RATE_LIMIT_WINDOW_MS,
  )
  hits.push(now)
  rateBuckets.set(userId, hits)
  if (rateBuckets.size > 10_000) rateBuckets.clear()
  return hits.length > RATE_LIMIT_MAX
}

function corsFor(origin: string | null): Record<string, string> {
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
    'X-Content-Type-Options': 'nosniff',
  }
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    headers['Access-Control-Allow-Origin'] = origin
  }
  return headers
}

function json(
  body: unknown,
  status: number,
  cors: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}

/// Resolves the caller from their Supabase session token. Returns null when
/// the token is absent, malformed or rejected. A user id supplied in the
/// request body is never trusted.
async function authenticate(req: Request): Promise<string | null> {
  const header = req.headers.get('Authorization') ?? ''
  const token = header.toLowerCase().startsWith('bearer ')
    ? header.slice(7).trim()
    : ''
  if (!token || !SUPABASE_URL || !SUPABASE_ANON_KEY) return null
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${token}`, apikey: SUPABASE_ANON_KEY },
    })
    if (!res.ok) return null
    const user = await res.json()
    return typeof user?.id === 'string' && user.id.length > 0 ? user.id : null
  } catch {
    return null
  }
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get('Origin')
  const cors = corsFor(origin)

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405, cors)
  }

  // A browser origin that is not allowlisted is refused outright. Native
  // clients send no Origin header and skip this check.
  if (origin && !ALLOWED_ORIGINS.includes(origin)) {
    return json({ error: 'Origin not allowed' }, 403, cors)
  }

  try {
    if (!DEEPSEEK_API_KEY) {
      console.error('[chat] DEEPSEEK_API_KEY is not configured')
      return json({ error: 'Service unavailable' }, 503, cors)
    }

    const userId = await authenticate(req)
    if (!userId) {
      return json({ error: 'Unauthorized' }, 401, cors)
    }

    if (rateLimited(userId)) {
      return json({ error: 'Too many requests' }, 429, {
        ...cors,
        'Retry-After': '60',
      })
    }

    const raw = await req.text()
    if (raw.length > MAX_BODY_BYTES) {
      return json({ error: 'Payload too large' }, 413, cors)
    }

    let parsed: unknown
    try {
      parsed = JSON.parse(raw)
    } catch {
      return json({ error: 'Malformed JSON' }, 400, cors)
    }
    if (typeof parsed !== 'object' || parsed === null) {
      return json({ error: 'Invalid request body' }, 400, cors)
    }

    const body = parsed as Record<string, unknown>
    const financial_context = body.financial_context

    // Schema validation: only well-formed chat turns reach the model.
    if (!Array.isArray(body.messages)) {
      return json({ error: 'Invalid request body' }, 400, cors)
    }
    if (body.messages.length > MAX_MESSAGES) {
      return json({ error: 'Too many messages' }, 400, cors)
    }
    const messages: Array<{ role: string; content: string }> = []
    for (const entry of body.messages) {
      if (typeof entry !== 'object' || entry === null) {
        return json({ error: 'Invalid message' }, 400, cors)
      }
      const { role, text, content } = entry as Record<string, unknown>
      if (role !== 'user' && role !== 'assistant') {
        return json({ error: 'Invalid message role' }, 400, cors)
      }
      // SafeSpendAIService sends `text`; the older shape used `content`.
      // Accept both so a client mid-rollout is not broken by the switch.
      const value = typeof text === 'string' ? text : content
      if (typeof value !== 'string' || value.length > MAX_MESSAGE_CHARS) {
        return json({ error: 'Invalid message content' }, 400, cors)
      }
      messages.push({ role, content: value })
    }

    const systemPrompt = buildSystemPrompt(
      (typeof financial_context === 'object' && financial_context !== null
        ? financial_context
        : {}) as Record<string, unknown>,
    )

    const deepseekRes = await fetch(DEEPSEEK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'deepseek-chat',
        messages: [
          { role: 'system', content: systemPrompt },
          ...messages,
        ],
        max_tokens: 1024,
        temperature: 0.7,
      }),
    })

    if (!deepseekRes.ok) {
      // Upstream detail stays in the server log. The client gets a generic
      // message, so provider errors and key state are not disclosed.
      const errText = await deepseekRes.text()
      console.error('[chat] upstream', deepseekRes.status, errText)
      return json(
        { error: 'Upstream service error' },
        deepseekRes.status === 429 ? 429 : 502,
        cors,
      )
    }

    const data = await deepseekRes.json()
    const reply = data.choices?.[0]?.message?.content ?? 'No response received.'
    const usage = data.usage ?? {}

    // The response shape SafeSpendAIService parses (AIResponse.fromJson).
    // `reply` is kept alongside it so an older client still works during a
    // staged rollout; it can be dropped once every build is on the new one.
    return json(
      {
        conversation_id:
          typeof body.conversation_id === 'string' ? body.conversation_id : null,
        type: 'text',
        text: reply,
        reply,
        tool_calls: [],
        suggestions: [],
        insights: [],
        usage: {
          prompt_tokens: usage.prompt_tokens ?? 0,
          completion_tokens: usage.completion_tokens ?? 0,
          model: 'deepseek-chat',
        },
      },
      200,
      cors,
    )
  } catch (err) {
    // Never echo the exception back: it can carry URLs, tokens and stack detail.
    console.error('[chat]', err)
    return json({ error: 'Internal error' }, 500, cors)
  }
})

// ─────────────────────────────────────────────
// System prompt builder
// ─────────────────────────────────────────────
function buildSystemPrompt(ctx: Record<string, unknown>): string {
  const currency = (ctx.currency as string) ?? 'USD'

  const fmt = (n: unknown) => {
    if (n === undefined || n === null) return 'N/A'
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(n as number)
  }

  const netWorth         = fmt(ctx.net_worth)
  const bankBalance      = fmt(ctx.bank_balance)
  const cashOnHand       = fmt(ctx.cash_on_hand)
  const monthlyIncome    = fmt(ctx.monthly_income)
  const thisMonthIncome  = fmt(ctx.this_month_income)
  const thisMonthExpenses = fmt(ctx.this_month_expenses)

  const rawIncome   = (ctx.this_month_income  as number) ?? 0
  const rawExpenses = (ctx.this_month_expenses as number) ?? 0
  const savingsRate = rawIncome > 0
    ? Math.round(((rawIncome - rawExpenses) / rawIncome) * 100)
    : 0

  const topCategories = ((ctx.top_categories as Array<{ name: string; amount: number }>) ?? [])
    .map(c => `  - ${c.name}: ${fmt(c.amount)}`).join('\n') || '  - No data yet'

  const goals = ((ctx.goals as Array<{ name: string; progress: number }>) ?? [])
    .map(g => `  - ${g.name}: ${g.progress}% complete`).join('\n') || '  - No active goals'

  const debts = ((ctx.debts as Array<{ name: string; remaining: number }>) ?? [])
    .map(d => `  - ${d.name}: ${fmt(d.remaining)} remaining`).join('\n') || '  - No active debts'

  const personalDebts = ((ctx.personal_debts as Array<{ name: string; remaining: number }>) ?? [])
    .map(d => `  - Owed to ${d.name}: ${fmt(d.remaining)}`).join('\n') || '  - None'

  const now = new Date()
  const monthYear = now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })

  return `You are SafeSpend AI Coach, a sharp and empathetic personal financial advisor built into the SafeSpend budget app.

═══ LIVE FINANCIAL SNAPSHOT — ${monthYear} ═══

OVERALL POSITION
- Net Worth:          ${netWorth}
- Bank Accounts:      ${bankBalance}
- Cash on Hand:       ${cashOnHand}
- Monthly Income:     ${monthlyIncome} (target)

THIS MONTH
- Income received:    ${thisMonthIncome}
- Total expenses:     ${thisMonthExpenses}
- Savings rate:       ${savingsRate >= 0 ? savingsRate : 0}%

TOP SPENDING CATEGORIES
${topCategories}

SAVINGS GOALS
${goals}

ACTIVE DEBTS
${debts}

MONEY OWED TO OTHERS
${personalDebts}

═══ YOUR COACHING GUIDELINES ═══
1. You have the user's REAL financial data above — use it proactively. Never ask for info you already have.
2. Be direct, concise, and specific. Give real numbers, percentages, and actionable steps.
3. Detect patterns — if expenses exceed income, flag it. If savings rate is low, say so clearly.
4. Speak in the same language the user writes in (French, Arabic, English, etc.).
5. Keep answers under 200 words unless the user asks for a detailed plan.
6. Be encouraging but honest — never sugarcoat financial risks.
7. If asked about a specific transaction detail you don't have, say so and suggest checking the app.
8. For goals and debts, calculate concrete timelines when possible based on current savings rate.`
}
