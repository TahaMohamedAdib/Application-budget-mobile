// Market Data Cache - 20 minute caching for quotes

import { CachedQuote, MarketQuote } from './types';

const CACHE_DURATION_MS = 20 * 60 * 1000; // 20 minutes

class MarketDataCache {
  private cache: Map<string, CachedQuote> = new Map();
  private persistenceKey = 'market-data-cache';

  constructor() {
    this.loadFromStorage();
  }

  private loadFromStorage(): void {
    try {
      const stored = localStorage.getItem(this.persistenceKey);
      if (stored) {
        const parsed = JSON.parse(stored) as Record<string, CachedQuote>;
        const now = Date.now();
        
        // Only load non-expired entries
        Object.entries(parsed).forEach(([ticker, cached]) => {
          if (cached.expiresAt > now) {
            this.cache.set(ticker, cached);
          }
        });
      }
    } catch (error) {
      console.warn('Failed to load market data cache from storage:', error);
    }
  }

  private saveToStorage(): void {
    try {
      const obj: Record<string, CachedQuote> = {};
      this.cache.forEach((value, key) => {
        obj[key] = value;
      });
      localStorage.setItem(this.persistenceKey, JSON.stringify(obj));
    } catch (error) {
      console.warn('Failed to save market data cache to storage:', error);
    }
  }

  get(ticker: string): MarketQuote | null {
    const normalizedTicker = ticker.toUpperCase();
    const cached = this.cache.get(normalizedTicker);
    
    if (!cached) {
      return null;
    }

    const now = Date.now();
    if (cached.expiresAt <= now) {
      // Cache expired
      this.cache.delete(normalizedTicker);
      this.saveToStorage();
      return null;
    }

    // Return cached quote with cached flag
    return {
      ...cached.quote,
      cached: true,
      cacheExpiresAt: new Date(cached.expiresAt).toISOString(),
    };
  }

  set(quote: MarketQuote): void {
    const normalizedTicker = quote.ticker.toUpperCase();
    const now = Date.now();
    const expiresAt = now + CACHE_DURATION_MS;

    const cachedQuote: CachedQuote = {
      quote: {
        ...quote,
        cached: false,
      },
      cachedAt: now,
      expiresAt,
    };

    this.cache.set(normalizedTicker, cachedQuote);
    this.saveToStorage();
  }

  getTimeUntilExpiry(ticker: string): number | null {
    const normalizedTicker = ticker.toUpperCase();
    const cached = this.cache.get(normalizedTicker);
    
    if (!cached) {
      return null;
    }

    const now = Date.now();
    const remaining = cached.expiresAt - now;
    return remaining > 0 ? remaining : null;
  }

  clear(): void {
    this.cache.clear();
    localStorage.removeItem(this.persistenceKey);
  }

  clearTicker(ticker: string): void {
    const normalizedTicker = ticker.toUpperCase();
    this.cache.delete(normalizedTicker);
    this.saveToStorage();
  }

  getAllCached(): MarketQuote[] {
    const now = Date.now();
    const quotes: MarketQuote[] = [];
    
    this.cache.forEach((cached) => {
      if (cached.expiresAt > now) {
        quotes.push({
          ...cached.quote,
          cached: true,
          cacheExpiresAt: new Date(cached.expiresAt).toISOString(),
        });
      }
    });
    
    return quotes;
  }
}

// Singleton instance
export const marketDataCache = new MarketDataCache();
