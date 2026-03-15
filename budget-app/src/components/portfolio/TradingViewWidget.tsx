import { useEffect, useRef, memo, useState } from 'react';
import { useStore } from '../../store/useStore';

interface TradingViewWidgetProps {
  height?: string;
}

function TradingViewWidgetComponent({ height = '300px' }: TradingViewWidgetProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const { portfolio } = useStore();
  const [selectedSymbol, setSelectedSymbol] = useState<string>('');

  // Get symbols from portfolio
  const symbols = portfolio.map(h => ({
    name: h.companyName || h.ticker,
    symbol: `NASDAQ:${h.ticker.toUpperCase()}`
  }));

  // Set default selected symbol
  useEffect(() => {
    if (symbols.length > 0 && !selectedSymbol) {
      setSelectedSymbol(symbols[0].symbol);
    }
  }, [symbols, selectedSymbol]);

  // Render simple chart
  useEffect(() => {
    const container = containerRef.current;
    if (!container || !selectedSymbol) return;

    container.innerHTML = '';

    const widgetDiv = document.createElement('div');
    widgetDiv.className = 'tradingview-widget-container__widget';
    container.appendChild(widgetDiv);

    const script = document.createElement('script');
    script.src = 'https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js';
    script.async = true;
    script.innerHTML = JSON.stringify({
      symbol: selectedSymbol,
      width: '100%',
      height: '100%',
      locale: 'en',
      dateRange: '3M',
      colorTheme: 'dark',
      isTransparent: true,
      autosize: true,
      largeChartUrl: '',
    });

    container.appendChild(script);

    return () => {
      container.innerHTML = '';
    };
  }, [selectedSymbol]);

  if (portfolio.length === 0) {
    return (
      <div className="p-6 text-center">
        <p className="text-gray-400 text-sm">Add holdings to see charts</p>
      </div>
    );
  }

  return (
    <div>
      {/* Symbol tabs */}
      <div className="flex gap-2 p-3 overflow-x-auto" style={{ scrollbarWidth: 'none' }}>
        {symbols.map((s) => (
          <button
            key={s.symbol}
            onClick={() => setSelectedSymbol(s.symbol)}
            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
              selectedSymbol === s.symbol
                ? 'bg-gold-500/20 text-gold-400'
                : 'bg-gray-700/50 text-gray-400 hover:bg-gray-700'
            }`}
          >
            {s.name}
          </button>
        ))}
      </div>

      {/* Chart */}
      <div 
        ref={containerRef}
        style={{ height, width: '100%' }}
      />
    </div>
  );
}

export const TradingViewWidget = memo(TradingViewWidgetComponent);
