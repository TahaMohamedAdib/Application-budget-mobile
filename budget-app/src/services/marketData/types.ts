// Market Data Types

export interface MarketQuote {
  ticker: string;
  name?: string;
  currency?: string;
  price: number;
  change?: number;
  changePct?: number;
  timestamp: string;
  source: 'trading.com' | 'manual';
  delayedMins?: number;
  cached: boolean;
  cacheExpiresAt?: string;
  error?: string;
}

export interface MarketDataConfig {
  enabled: boolean;
  sessionToken?: string;
  accountId?: string;
}

export interface CachedQuote {
  quote: MarketQuote;
  cachedAt: number;
  expiresAt: number;
}

export type MarketDataStatus = 
  | 'connected'
  | 'not_configured'
  | 'auth_required'
  | 'rate_limited'
  | 'error';

export interface MarketDataState {
  status: MarketDataStatus;
  lastError?: string;
  config: MarketDataConfig;
}
