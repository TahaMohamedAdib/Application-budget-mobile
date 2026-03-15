import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Check, Search } from 'lucide-react';
import { useStore } from '../../store/useStore';

interface AddHoldingModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const popularStocks = [
  { ticker: 'AAPL', name: 'Apple Inc.' },
  { ticker: 'MSFT', name: 'Microsoft Corporation' },
  { ticker: 'GOOGL', name: 'Alphabet Inc.' },
  { ticker: 'AMZN', name: 'Amazon.com Inc.' },
  { ticker: 'TSLA', name: 'Tesla Inc.' },
  { ticker: 'META', name: 'Meta Platforms Inc.' },
  { ticker: 'NVDA', name: 'NVIDIA Corporation' },
  { ticker: 'JPM', name: 'JPMorgan Chase & Co.' },
];

export const AddHoldingModal: React.FC<AddHoldingModalProps> = ({ isOpen, onClose }) => {
  const { addHolding } = useStore();
  const [ticker, setTicker] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [quantity, setQuantity] = useState('');
  const [buyPrice, setBuyPrice] = useState('');
  const [currentPrice, setCurrentPrice] = useState('');
  const [buyDate, setBuyDate] = useState('');

  const handleSelectStock = (stock: { ticker: string; name: string }) => {
    setTicker(stock.ticker);
    setCompanyName(stock.name);
    // Simulate fetching current price (in production, fetch from trading.com)
    const simulatedPrice = Math.round((50 + Math.random() * 450) * 100) / 100;
    setCurrentPrice(simulatedPrice.toString());
  };

  const handleSubmit = () => {
    if (!ticker.trim() || !quantity || !buyPrice) return;

    addHolding({
      ticker: ticker.toUpperCase().trim(),
      companyName: companyName.trim() || undefined,
      quantity: parseFloat(quantity),
      buyPrice: parseFloat(buyPrice),
      buyDate: buyDate || undefined,
      currentPrice: parseFloat(currentPrice) || parseFloat(buyPrice),
      lastUpdated: new Date().toISOString(),
      source: 'trading.com',
    });

    setTicker('');
    setCompanyName('');
    setQuantity('');
    setBuyPrice('');
    setCurrentPrice('');
    setBuyDate('');
    onClose();
  };

  const isValid = ticker.trim() && quantity && parseFloat(quantity) > 0 && buyPrice && parseFloat(buyPrice) > 0;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 z-50"
            onClick={onClose}
          />
          <motion.div
            initial={{ opacity: 0, y: '100%' }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 bg-theme-modal border-t border-theme-divider rounded-t-3xl z-50 max-h-[90vh] overflow-y-auto"
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <button onClick={onClose} className="w-10 h-10 rounded-full flex items-center justify-center">
                  <X className="w-6 h-6 text-theme-secondary" />
                </button>
                <h2 className="text-lg font-semibold text-theme-primary">Add Stock</h2>
                <button
                  onClick={handleSubmit}
                  disabled={!isValid}
                  className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center"
                >
                  <Check className={`w-5 h-5 ${isValid ? 'text-gold-400' : 'text-theme-tertiary'}`} />
                </button>
              </div>

              {/* Ticker Input */}
              <div className="mb-4">
                <p className="text-theme-tertiary text-sm mb-2">Stock Ticker</p>
                <div className="relative">
                  <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-theme-tertiary" />
                  <input
                    type="text"
                    placeholder="e.g., AAPL, MSFT, GOOGL"
                    value={ticker}
                    onChange={(e) => setTicker(e.target.value.toUpperCase())}
                    className="w-full pl-12 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none uppercase"
                  />
                </div>
              </div>

              {/* Popular Stocks */}
              {!ticker && (
                <div className="mb-6">
                  <p className="text-theme-tertiary text-sm mb-2">Popular Stocks</p>
                  <div className="flex flex-wrap gap-2">
                    {popularStocks.map((stock) => (
                      <button
                        key={stock.ticker}
                        onClick={() => handleSelectStock(stock)}
                        className="px-3 py-1.5 bg-theme-badge rounded-lg text-sm font-medium text-theme-secondary hover:bg-theme-surface-hover"
                      >
                        {stock.ticker}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Company Name (optional) */}
              <div className="mb-4">
                <p className="text-theme-tertiary text-sm mb-2">Company Name (optional)</p>
                <input
                  type="text"
                  placeholder="e.g., Apple Inc."
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                />
              </div>

              {/* Quantity */}
              <div className="mb-4">
                <p className="text-theme-tertiary text-sm mb-2">Number of Shares</p>
                <input
                  type="number"
                  inputMode="decimal"
                  placeholder="0"
                  value={quantity}
                  onChange={(e) => setQuantity(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                />
              </div>

              {/* Buy Price */}
              <div className="mb-4">
                <p className="text-theme-tertiary text-sm mb-2">Buy Price (per share)</p>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">$</span>
                  <input
                    type="number"
                    inputMode="decimal"
                    placeholder="0.00"
                    value={buyPrice}
                    onChange={(e) => setBuyPrice(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                  />
                </div>
              </div>

              {/* Current Price */}
              <div className="mb-4">
                <p className="text-theme-tertiary text-sm mb-2">Current Price (per share)</p>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">$</span>
                  <input
                    type="number"
                    inputMode="decimal"
                    placeholder="0.00"
                    value={currentPrice}
                    onChange={(e) => setCurrentPrice(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary placeholder:text-theme outline-none"
                  />
                </div>
                <p className="text-xs text-theme-tertiary mt-1">Prices from trading.com (delayed ~20 min)</p>
              </div>

              {/* Buy Date (optional) */}
              <div className="mb-6">
                <p className="text-theme-tertiary text-sm mb-2">Buy Date (optional)</p>
                <input
                  type="date"
                  value={buyDate}
                  onChange={(e) => setBuyDate(e.target.value)}
                  className="w-full px-4 py-3 bg-theme-badge border border-theme-divider rounded-xl text-theme-primary outline-none"
                />
              </div>

              {/* Submit Button */}
              <button
                onClick={handleSubmit}
                disabled={!isValid}
                className="w-full py-4 bg-gold-500 hover:bg-gold-600 disabled:bg-theme-badge disabled:text-theme-tertiary text-white font-semibold rounded-xl transition-colors"
              >
                Add Stock
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
