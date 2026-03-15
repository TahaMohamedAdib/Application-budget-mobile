// Trading.com Connector
// 
// IMPORTANT: Trading.com does NOT provide a public API for market data.
// This connector is designed to work IF/WHEN trading.com provides API access.
// Currently, it will return an error indicating configuration is required.
//
// See TRADING_COM_DEV_NOTES.md for full investigation details.

import { MarketQuote, MarketDataConfig, MarketDataStatus } from './types';

// Configuration - would be loaded from environment/settings
let config: MarketDataConfig = {
  enabled: false,
  sessionToken: undefined,
  accountId: undefined,
};

// Rate limiting
const MIN_REQUEST_INTERVAL_MS = 1000; // 1 second between requests
let lastRequestTime = 0;

export function setTradingComConfig(newConfig: Partial<MarketDataConfig>): void {
  config = { ...config, ...newConfig };
}

export function getTradingComConfig(): MarketDataConfig {
  return { ...config };
}

export function getTradingComStatus(): MarketDataStatus {
  if (!config.enabled) {
    return 'not_configured';
  }
  if (!config.sessionToken) {
    return 'auth_required';
  }
  return 'connected';
}

export async function fetchQuoteFromTradingCom(ticker: string): Promise<MarketQuote> {
  const status = getTradingComStatus();
  
  // Check if trading.com is configured
  if (status === 'not_configured') {
    return {
      ticker: ticker.toUpperCase(),
      price: 0,
      timestamp: new Date().toISOString(),
      source: 'trading.com',
      cached: false,
      error: 'Trading.com integration is not configured. Please connect your trading.com account or enter prices manually.',
    };
  }

  if (status === 'auth_required') {
    return {
      ticker: ticker.toUpperCase(),
      price: 0,
      timestamp: new Date().toISOString(),
      source: 'trading.com',
      cached: false,
      error: 'Trading.com requires authentication. Please provide your session token in settings.',
    };
  }

  // Rate limiting
  const now = Date.now();
  const timeSinceLastRequest = now - lastRequestTime;
  if (timeSinceLastRequest < MIN_REQUEST_INTERVAL_MS) {
    await new Promise(resolve => setTimeout(resolve, MIN_REQUEST_INTERVAL_MS - timeSinceLastRequest));
  }
  lastRequestTime = Date.now();

  try {
    // IMPORTANT: This is where the actual trading.com API call would go
    // Currently, trading.com does not expose a public API, so this will fail
    // 
    // If trading.com ever provides an API, the implementation would look like:
    //
    // const response = await fetch(`https://api.trading.com/v1/quotes/${ticker}`, {
    //   headers: {
    //     'Authorization': `Bearer ${config.sessionToken}`,
    //     'X-Account-ID': config.accountId || '',
    //   },
    // });
    //
    // if (!response.ok) {
    //   throw new Error(`Trading.com API error: ${response.status}`);
    // }
    //
    // const data = await response.json();
    // return normalizeQuote(data);

    // For now, return an error indicating the API is not available
    throw new Error('Trading.com does not expose a public market data API. See TRADING_COM_DEV_NOTES.md for details.');

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    return {
      ticker: ticker.toUpperCase(),
      price: 0,
      timestamp: new Date().toISOString(),
      source: 'trading.com',
      cached: false,
      error: errorMessage,
    };
  }
}

// Normalize response from trading.com API (when/if available)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function normalizeQuote(rawData: any, ticker: string): MarketQuote {
  // This would parse the trading.com response format
  // Structure TBD based on actual API response
  return {
    ticker: ticker.toUpperCase(),
    name: rawData.name || rawData.symbol_name || undefined,
    currency: rawData.currency || 'USD',
    price: parseFloat(rawData.price || rawData.last || rawData.bid || 0),
    change: rawData.change ? parseFloat(rawData.change) : undefined,
    changePct: rawData.change_percent ? parseFloat(rawData.change_percent) : undefined,
    timestamp: rawData.timestamp || new Date().toISOString(),
    source: 'trading.com',
    delayedMins: 20, // Trading.com data is typically delayed
    cached: false,
  };
}
