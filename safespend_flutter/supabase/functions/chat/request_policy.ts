export const allowedGeminiModels = new Set(['gemini-2.5-flash'])
export const allowedGeminiEndpoints = new Set(['generateContent'])

export function extractBearerToken(header: string | null): string | null {
  if (header === null) return null
  const match = /^Bearer[ \t]+([^\s]+)$/i.exec(header)
  return match?.[1] ?? null
}

export function isAnonymousCredential(
  token: string,
  supabaseAnonKey: string,
): boolean {
  return token === supabaseAnonKey
}

export function isAllowedGeminiTarget(
  model: unknown,
  endpoint: unknown,
): boolean {
  return (
    typeof model === 'string' &&
    typeof endpoint === 'string' &&
    allowedGeminiModels.has(model) &&
    allowedGeminiEndpoints.has(endpoint)
  )
}
