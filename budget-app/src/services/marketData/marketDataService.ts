// Market Data Service - Main entry point for fetching quotes
// Handles caching, rate limiting, and fallback logic

import { MarketQuote, MarketDataStatus } from './types';
import { marketDataCache } from './cache';
import { fetchQuoteFromTradingCom, getTradingComStatus } from './tradingComConnector';

export interface FetchQuoteOptions {
  forceRefresh?: boolean;
  allowManualFallback?: boolean;
}

export async function fetchQuote(
  ticker: string,
  options: FetchQuoteOptions = {}
): Promise<MarketQuote> {
  const normalizedTicker = ticker.toUpperCase();
  const { forceRefresh = false, allowManualFallback = true } = options;

  // Check cache first (unless force refresh)
  if (!forceRefresh) {
    const cached = marketDataCache.get(normalizedTicker);
    if (cached) {
      console.log(`[MarketData] Returning cached quote for ${normalizedTicker}`);
      return cached;
    }
  }

  // Try to fetch from trading.com
  console.log(`[MarketData] Fetching quote for ${normalizedTicker} from trading.com`);
  const quote = await fetchQuoteFromTradingCom(normalizedTicker);

  // If successful (no error), cache it
  if (!quote.error && quote.price > 0) {
    marketDataCache.set(quote);
    return quote;
  }

  // If there's an error but we have a stale cache, return that
  const staleCache = marketDataCache.get(normalizedTicker);
  if (staleCache) {
    console.log(`[MarketData] Returning stale cache for ${normalizedTicker} due to fetch error`);
    return {
      ...staleCache,
      error: quote.error ? `${quote.error} (showing last known price)` : undefined,
    };
  }

  // If manual fallback is allowed, return the error quote
  // The UI will handle showing manual entry option
  if (allowManualFallback) {
    return quote;
  }

  return quote;
}

export async function fetchMultipleQuotes(
  tickers: string[],
  options: FetchQuoteOptions = {}
): Promise<Map<string, MarketQuote>> {
  const results = new Map<string, MarketQuote>();
  
  // Fetch sequentially to respect rate limits
  for (const ticker of tickers) {
    const quote = await fetchQuote(ticker, options);
    results.set(ticker.toUpperCase(), quote);
  }
  
  return results;
}

export function getMarketDataStatus(): MarketDataStatus {
  return getTradingComStatus();
}

export function getCacheTimeRemaining(ticker: string): number | null {
  return marketDataCache.getTimeUntilExpiry(ticker);
}

export function clearCache(): void {
  marketDataCache.clear();
}

export function clearTickerCache(ticker: string): void {
  marketDataCache.clearTicker(ticker);
}

// Manual price entry - for when trading.com is not available
export function setManualPrice(
  ticker: string,
  price: number,
  name?: string
): MarketQuote {
  const quote: MarketQuote = {
    ticker: ticker.toUpperCase(),
    name,
    price,
    timestamp: new Date().toISOString(),
    source: 'manual',
    cached: false,
    delayedMins: undefined,
  };
  
  marketDataCache.set(quote);
  return quote;
}

// Export for use in components
export { marketDataCache } from './cache';
export * from './types';
