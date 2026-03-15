# Trading.com Market Data Integration - DEV NOTES

## Investigation Findings (Date: 2026-02-05)

### About Trading.com
Trading.com is a **regulated forex/CFD broker** (not a stock data API provider).
- Website: https://www.trading.com
- Primary focus: Forex, Commodities, Indices CFDs
- Platforms: MT5, WebTrader (proprietary)

### API Availability
**CRITICAL FINDING:** Trading.com does NOT expose a public REST API for fetching market quotes.

Their price data is delivered through:
1. **MetaTrader 5 (MT5)** - Proprietary protocol, requires trading account
2. **WebTrader** - Browser-based, uses WebSocket with authenticated sessions
3. **TradingView integration** - Charts only, no programmatic access

### Network Request Analysis
When accessing trading.com WebTrader:
- Authentication required (trading account login)
- WebSocket connection: `wss://webtrader.trading.com/...`
- Session cookies required for all data requests
- No public endpoints discovered

### Legal/ToS Considerations
- Scraping trading.com would violate their Terms of Service
- No official API documentation or developer program found
- Data is proprietary and intended only for their trading clients

## Implementation Decision

Since trading.com does not provide a usable market-data endpoint without:
1. A trading account
2. Authenticated session
3. Potential ToS violation

We implement a **configurable Market Data Adapter** with:
1. **Trading.com connector** (requires user-provided credentials/session)
2. **Fallback limitation screen** when not configured
3. **Manual price entry** as ultimate fallback

## Adapter Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Market Data Adapter                   │
├─────────────────────────────────────────────────────────┤
│  GET /api/market/quote?ticker=XXX                       │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │ Trading.com │ -> │   Cache     │ -> │  Response   │ │
│  │  Connector  │    │ (20 min)    │    │ Normalizer  │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
│         │                                               │
│         v                                               │
│  ┌─────────────┐                                       │
│  │  Fallback   │ (if no credentials configured)        │
│  │   Screen    │                                       │
│  └─────────────┘                                       │
└─────────────────────────────────────────────────────────┘
```

## Response Format (Normalized)

```json
{
  "ticker": "AAPL",
  "name": "Apple Inc.",
  "currency": "USD",
  "price": 185.50,
  "change": 2.30,
  "changePct": 1.25,
  "timestamp": "2026-02-05T18:30:00Z",
  "source": "trading.com",
  "delayedMins": 20,
  "cached": true,
  "cacheExpiresAt": "2026-02-05T18:50:00Z"
}
```

## Configuration Required

Environment variables:
```
TRADING_COM_ENABLED=false          # Set to true when credentials available
TRADING_COM_SESSION_TOKEN=         # User-provided session token (if applicable)
TRADING_COM_ACCOUNT_ID=            # Trading account ID (if applicable)
```

## Fallback Behavior

When trading.com integration is not configured:
1. Show clear message: "Trading.com integration requires authorized access"
2. Allow manual price entry for holdings
3. Display "Manual entry" as source instead of "trading.com"

## Future Improvements

If trading.com ever provides:
- Public API access
- Developer program
- OAuth integration

Update the connector in `tradingComConnector.ts`
