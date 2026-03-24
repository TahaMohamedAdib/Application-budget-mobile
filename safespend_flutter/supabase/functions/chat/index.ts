const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const DEEPSEEK_API_KEY = Deno.env.get('DEEPSEEK_API_KEY') ?? ''
const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions'

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { messages, financial_context } = await req.json()

    if (!DEEPSEEK_API_KEY) {
      throw new Error('DEEPSEEK_API_KEY is not configured')
    }

    const systemPrompt = buildSystemPrompt(financial_context ?? {})

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
          ...(messages ?? []),
        ],
        max_tokens: 1024,
        temperature: 0.7,
      }),
    })

    if (!deepseekRes.ok) {
      const errText = await deepseekRes.text()
      throw new Error(`DeepSeek API ${deepseekRes.status}: ${errText}`)
    }

    const data = await deepseekRes.json()
    const reply = data.choices?.[0]?.message?.content ?? 'No response received.'

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('[chat]', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
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
