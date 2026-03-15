import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  TrendingUp, TrendingDown, Plus, RefreshCw, Clock, Trash2, 
  HelpCircle, X, Info, AlertTriangle, Wifi, Edit3
} from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { StockHolding } from '../../types';
import { AddHoldingModal } from '../modals/AddHoldingModal';
import { PortfolioChart } from './PortfolioChart';
import { TradingViewWidget } from './TradingViewWidget';
import { 
  fetchQuote, 
  getMarketDataStatus, 
  getCacheTimeRemaining,
  setManualPrice
} from '../../services/marketData';

interface PortfolioSectionEnhancedProps {
  onHoldingClick?: (holding: StockHolding) => void;
}

export const PortfolioSectionEnhanced: React.FC<PortfolioSectionEnhancedProps> = ({ onHoldingClick }) => {
  const { 
    portfolio, 
    settings, 
    getPortfolioValue, 
    getPortfolioPL, 
    updateHoldingPrice, 
    deleteHolding,
    addPortfolioSnapshot 
  } = useStore();
  
  const [showAddModal, setShowAddModal] = useState(false);
  const [showLearnModal, setShowLearnModal] = useState(false);
  const [showConfigModal, setShowConfigModal] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [lastRefreshError, setLastRefreshError] = useState<string | null>(null);
  const [marketStatus, setMarketStatus] = useState(getMarketDataStatus());
  const [quotesLoading, setQuotesLoading] = useState<Set<string>>(new Set());
  const [manualPriceEdit, setManualPriceEdit] = useState<string | null>(null);
  const [manualPriceValue, setManualPriceValue] = useState('');

  const totalValue = getPortfolioValue();
  const totalPL = getPortfolioPL();
  const totalInvested = portfolio.reduce((sum, h) => sum + (h.quantity * h.buyPrice), 0);
  const plPercent = totalInvested > 0 ? ((totalPL / totalInvested) * 100) : 0;

  // Add snapshot when component mounts or portfolio changes
  useEffect(() => {
    if (portfolio.length > 0) {
      addPortfolioSnapshot();
    }
  }, [portfolio.length, totalValue]);

  // Fetch quote for a single holding
  const fetchHoldingQuote = useCallback(async (holding: StockHolding, forceRefresh = false) => {
    // Check cache time remaining
    const cacheRemaining = getCacheTimeRemaining(holding.ticker);
    if (!forceRefresh && cacheRemaining && cacheRemaining > 0) {
      console.log(`[Portfolio] ${holding.ticker} cached for ${Math.round(cacheRemaining / 1000 / 60)}m more`);
      return null; // Still cached, no update needed
    }

    setQuotesLoading(prev => new Set(prev).add(holding.ticker));
    
    try {
      const quote = await fetchQuote(holding.ticker, { forceRefresh });
      
      if (quote.error) {
        console.warn(`[Portfolio] Error fetching ${holding.ticker}:`, quote.error);
        return quote;
      }
      
      if (quote.price > 0) {
        updateHoldingPrice(holding.id, quote.price);
      }
      
      return quote;
    } finally {
      setQuotesLoading(prev => {
        const next = new Set(prev);
        next.delete(holding.ticker);
        return next;
      });
    }
  }, [updateHoldingPrice]);

  // Refresh all prices
  const handleRefreshPrices = async () => {
    setRefreshing(true);
    setLastRefreshError(null);
    setMarketStatus(getMarketDataStatus());
    
    const errors: string[] = [];
    
    try {
      for (const holding of portfolio) {
        const quote = await fetchHoldingQuote(holding, false);
        if (quote?.error) {
          errors.push(`${holding.ticker}: ${quote.error}`);
        }
      }
      
      // Update snapshot after refresh
      addPortfolioSnapshot();
      
      if (errors.length > 0) {
        if (marketStatus === 'not_configured') {
          setLastRefreshError("Enter prices manually or view live prices in the TradingView widget above.");
        } else {
          setLastRefreshError(`Some prices couldn't be updated. Showing last known prices.`);
        }
      }
    } catch (error) {
      setLastRefreshError("Couldn't refresh right now. Showing last known price.");
    }
    
    setRefreshing(false);
  };

  // Handle manual price entry
  const handleManualPriceSubmit = (holdingId: string, ticker: string) => {
    const price = parseFloat(manualPriceValue);
    if (price > 0) {
      setManualPrice(ticker, price);
      updateHoldingPrice(holdingId, price);
      addPortfolioSnapshot();
    }
    setManualPriceEdit(null);
    setManualPriceValue('');
  };

  const getLastUpdatedText = () => {
    if (portfolio.length === 0) return null;
    
    const dates = portfolio.map((h) => new Date(h.lastUpdated));
    const oldest = new Date(Math.min(...dates.map((d) => d.getTime())));
    const now = new Date();
    const minutes = Math.floor((now.getTime() - oldest.getTime()) / (1000 * 60));
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
  };

  const handleDeleteHolding = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (confirm('Delete this holding?')) {
      deleteHolding(id);
    }
  };

  // Empty state
  if (portfolio.length === 0) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-theme-primary flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-gold-500" />
            Portfolio (Compte-Titres)
          </h3>
          <button
            onClick={() => setShowLearnModal(true)}
            className="w-8 h-8 rounded-full bg-theme-badge flex items-center justify-center"
          >
            <HelpCircle className="w-4 h-4 text-theme-secondary" />
          </button>
        </div>
        
        <div className="text-center py-8">
          <div className="w-20 h-20 bg-gold-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <TrendingUp className="w-10 h-10 text-gold-500" />
          </div>
          <h4 className="text-lg font-semibold text-theme-primary mb-2">
            Track Your Investments
          </h4>
          <p className="text-theme-secondary mb-6 max-w-xs mx-auto">
            Add your first investment to track your portfolio value and see how your money grows.
          </p>
          <button
            onClick={() => setShowAddModal(true)}
            className="px-6 py-3 bg-gold-500 hover:bg-gold-600 text-white rounded-xl font-medium flex items-center gap-2 mx-auto"
          >
            <Plus className="w-5 h-5" />
            Add Investment
          </button>
        </div>

        <AddHoldingModal
          isOpen={showAddModal}
          onClose={() => setShowAddModal(false)}
        />

        <LearnModal 
          isOpen={showLearnModal} 
          onClose={() => setShowLearnModal(false)} 
        />
      </motion.div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-theme-primary flex items-center gap-2">
          <TrendingUp className="w-5 h-5 text-emerald-500" />
          Portfolio (Compte-Titres)
        </h3>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowLearnModal(true)}
            className="w-8 h-8 rounded-full bg-theme-badge flex items-center justify-center"
          >
            <HelpCircle className="w-4 h-4 text-theme-secondary" />
          </button>
          <button
            onClick={handleRefreshPrices}
            disabled={refreshing}
            className="w-8 h-8 rounded-full bg-theme-badge flex items-center justify-center"
          >
            <RefreshCw className={`w-4 h-4 text-theme-secondary ${refreshing ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="w-8 h-8 rounded-full bg-gold-500 flex items-center justify-center"
          >
            <Plus className="w-4 h-4 text-theme-primary" />
          </button>
        </div>
      </div>

      {/* TradingView Live Prices Widget */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="rounded-2xl overflow-hidden shadow-lg"
        style={{ background: 'rgb(17, 24, 39)' }}
      >
        <div className="px-4 py-3 flex items-center justify-between" style={{ background: 'rgb(17, 24, 39)', borderBottom: '1px solid rgba(55, 65, 81, 0.5)' }}>
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-gold-500 rounded-full animate-pulse" />
            <span className="text-sm font-medium text-theme-primary">Live Market Prices</span>
          </div>
          <span className="text-xs bg-gold-500/20 text-gold-400 px-2 py-1 rounded-full font-medium">
            TradingView
          </span>
        </div>
        <TradingViewWidget height="500px" />
      </motion.div>

      {/* Portfolio Value Chart (Historical) */}
      <PortfolioChart />

      {/* Summary Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4"
      >
        <div className="grid grid-cols-2 gap-4 mb-4">
          <div>
            <p className="text-xs text-theme-tertiary mb-1">Total Invested</p>
            <p className="text-lg font-bold text-theme-primary">
              {formatCurrency(totalInvested, settings.currency)}
            </p>
          </div>
          <div>
            <p className="text-xs text-theme-tertiary mb-1">Current Value</p>
            <p className="text-lg font-bold text-theme-primary">
              {formatCurrency(totalValue, settings.currency)}
            </p>
          </div>
          <div>
            <p className="text-xs text-theme-tertiary mb-1">Profit / Loss</p>
            <p className={`text-lg font-bold ${totalPL >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
              {totalPL >= 0 ? '+' : ''}{formatCurrency(totalPL, settings.currency)}
            </p>
          </div>
          <div>
            <p className="text-xs text-theme-tertiary mb-1">Return %</p>
            <div className={`flex items-center gap-1 ${totalPL >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
              {totalPL >= 0 ? (
                <TrendingUp className="w-4 h-4" />
              ) : (
                <TrendingDown className="w-4 h-4" />
              )}
              <span className="text-lg font-bold">{plPercent.toFixed(2)}%</span>
            </div>
          </div>
        </div>
        
        {/* Last Updated + Source */}
        <div className="flex items-center justify-between pt-3 border-t border-theme-divider">
          <div className="flex items-center gap-1 text-xs text-theme-tertiary">
            <Clock className="w-3 h-3" />
            <span>Last price update: {getLastUpdatedText()}</span>
          </div>
          <div className="flex items-center gap-1 text-xs">
<>
              <Wifi className="w-3 h-3 text-gold-500" />
              <span className="text-gold-500">TradingView</span>
            </>
          </div>
        </div>

        {/* Delay Badge */}
        <div className="mt-2 flex items-center justify-center">
          <span className="text-xs text-theme-tertiary bg-theme-badge px-2 py-1 rounded-full">
            ⏱️ Prices delayed ~20 min
          </span>
        </div>

        {/* Error Message */}
        {lastRefreshError && (
          <div className="mt-2 p-2 bg-amber-500/10 border border-amber-500/20 rounded-lg">
            <p className="text-xs text-amber-300">{lastRefreshError}</p>
          </div>
        )}

        {/* TradingView Info */}
        <div className="mt-2 p-3 bg-gold-500/10 border border-gold-500/20 rounded-lg">
          <div className="flex items-start gap-2">
            <Info className="w-4 h-4 text-gold-400 mt-0.5 flex-shrink-0" />
            <div>
              <p className="text-xs text-gold-400 font-medium">Live Prices via TradingView</p>
              <p className="text-xs text-gold-400/70 mt-1">
                View real-time prices in the widget above. Enter your buy price and current price manually to track P/L.
              </p>
            </div>
          </div>
        </div>
      </motion.div>

      {/* Beginner Explanations */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-blue-500/10 border border-blue-500/20 rounded-2xl p-4"
      >
        <div className="flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-400 mt-0.5 flex-shrink-0" />
          <div className="text-sm">
            <p className="font-medium text-blue-300 mb-1">Understanding Your Portfolio</p>
            <ul className="text-blue-400/70 space-y-1 text-xs">
              <li><strong>Invested</strong> = what you paid when you bought</li>
              <li><strong>Current value</strong> = shares × current price</li>
              <li><strong>Profit/Loss</strong> = current value − invested</li>
            </ul>
          </div>
        </div>
      </motion.div>

      {/* Holdings List */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl overflow-hidden"
      >
        <div className="p-4 border-b border-theme-divider">
          <h4 className="font-medium text-theme-primary">Your Holdings</h4>
        </div>
        
        <div className="divide-y divide-white/10">
          <AnimatePresence>
            {portfolio.map((holding) => {
              const investedAmount = holding.quantity * holding.buyPrice;
              const currentValue = holding.quantity * holding.currentPrice;
              const pl = currentValue - investedAmount;
              const plPct = investedAmount > 0 ? ((pl / investedAmount) * 100) : 0;
              
              return (
                <motion.div
                  key={holding.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  onClick={() => onHoldingClick?.(holding)}
                  className="p-4 cursor-pointer hover:bg-theme-surface/50"
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-blue-500/10 rounded-lg flex items-center justify-center">
                        <span className="text-sm font-bold text-blue-500">
                          {holding.ticker.slice(0, 2)}
                        </span>
                      </div>
                      <div>
                        <p className="font-semibold text-theme-primary">{holding.ticker}</p>
                        {holding.companyName && (
                          <p className="text-xs text-theme-tertiary">{holding.companyName}</p>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-theme-primary">
                        {formatCurrency(currentValue, settings.currency)}
                      </p>
                      <p className={`text-xs ${pl >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
                        {pl >= 0 ? '+' : ''}{formatCurrency(pl, settings.currency)} ({plPct.toFixed(1)}%)
                      </p>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-4 gap-2 text-xs">
                    <div>
                      <p className="text-theme-tertiary">Shares</p>
                      <p className="text-theme-secondary font-medium">{holding.quantity}</p>
                    </div>
                    <div>
                      <p className="text-theme-tertiary">Buy Price</p>
                      <p className="text-theme-secondary font-medium">
                        {formatCurrency(holding.buyPrice, settings.currency)}
                      </p>
                    </div>
                    <div>
                      <p className="text-theme-tertiary">Current</p>
                      {manualPriceEdit === holding.id ? (
                        <div className="flex items-center gap-1">
                          <input
                            type="number"
                            value={manualPriceValue}
                            onChange={(e) => setManualPriceValue(e.target.value)}
                            onKeyPress={(e) => e.key === 'Enter' && handleManualPriceSubmit(holding.id, holding.ticker)}
                            className="w-16 px-1 py-0.5 text-xs border border-theme-divider rounded bg-theme-badge text-theme-primary"
                            placeholder={holding.currentPrice.toString()}
                            autoFocus
                          />
                          <button
                            onClick={() => handleManualPriceSubmit(holding.id, holding.ticker)}
                            className="text-gold-500 text-xs"
                          >
                            ✓
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-1">
                          <p className="text-theme-secondary font-medium">
                            {formatCurrency(holding.currentPrice, settings.currency)}
                          </p>
                          {quotesLoading.has(holding.ticker) && (
                            <RefreshCw className="w-3 h-3 text-gray-400 animate-spin" />
                          )}
                        </div>
                      )}
                    </div>
                    <div className="flex justify-end items-end gap-1">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setManualPriceEdit(holding.id);
                          setManualPriceValue(holding.currentPrice.toString());
                        }}
                        className="p-1.5 rounded-lg hover:bg-theme-surface-hover"
                        title="Edit price manually"
                      >
                        <Edit3 className="w-4 h-4 text-gray-400 hover:text-blue-500" />
                      </button>
                      <button
                        onClick={(e) => handleDeleteHolding(holding.id, e)}
                        className="p-1.5 rounded-lg hover:bg-theme-surface-hover"
                      >
                        <Trash2 className="w-4 h-4 text-gray-400 hover:text-red-500" />
                      </button>
                    </div>
                  </div>
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>

        {/* Dividends Placeholder */}
        <div className="p-4 border-t border-theme-divider bg-theme-surface/50">
          <p className="text-sm text-theme-tertiary text-center">
            💰 Dividends tracking (coming soon)
          </p>
        </div>
      </motion.div>

      {/* Modals */}
      <AddHoldingModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
      />

      <LearnModal 
        isOpen={showLearnModal} 
        onClose={() => setShowLearnModal(false)} 
      />

      <TradingComConfigModal
        isOpen={showConfigModal}
        onClose={() => setShowConfigModal(false)}
      />
    </div>
  );
};

// Learn Modal Component
const LearnModal: React.FC<{ isOpen: boolean; onClose: () => void }> = ({ isOpen, onClose }) => {
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
            className="fixed bottom-0 left-0 right-0 bg-theme-modal border-t border-theme-divider rounded-t-3xl z-50 max-h-[80vh] overflow-y-auto"
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-theme-primary">
                  What is a Compte-Titres?
                </h2>
                <button onClick={onClose} className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center">
                  <X className="w-5 h-5 text-theme-secondary" />
                </button>
              </div>

              <div className="space-y-4 text-theme-secondary">
                <p>
                  A <strong>Compte-Titres</strong> (securities account) is a type of investment account 
                  that allows you to buy and hold stocks, bonds, ETFs, and other financial securities.
                </p>

                <div className="bg-gold-500/10 border border-gold-500/20 rounded-xl p-4">
                  <h3 className="font-semibold text-gold-400 mb-2">
                    📈 Key Benefits
                  </h3>
                  <ul className="space-y-2 text-sm text-gold-400/70">
                    <li>• No limits on deposits or withdrawals</li>
                    <li>• Access to a wide range of investments</li>
                    <li>• Potential for long-term growth</li>
                    <li>• Flexibility to buy and sell anytime</li>
                  </ul>
                </div>

                <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-4">
                  <h3 className="font-semibold text-blue-300 mb-2">
                    📊 How We Track It
                  </h3>
                  <ul className="space-y-2 text-sm text-blue-400/70">
                    <li>• <strong>Add your holdings</strong> - Enter what stocks you own</li>
                    <li>• <strong>Live prices</strong> - View real-time prices via TradingView widget</li>
                    <li>• <strong>Track performance</strong> - See your gains and losses</li>
                    <li>• <strong>Portfolio chart</strong> - Visualize your growth over time</li>
                  </ul>
                </div>

                <div className="bg-amber-500/10 border border-amber-500/20 rounded-xl p-4">
                  <h3 className="font-semibold text-amber-300 mb-2">
                    ⚠️ Important Note
                  </h3>
                  <p className="text-sm text-amber-400/70">
                    Prices shown may be delayed ~20 minutes depending on the data source. 
                    This app is for tracking purposes only and does not provide investment advice.
                  </p>
                </div>
              </div>

              <button
                onClick={onClose}
                className="w-full mt-6 py-4 bg-gold-500 hover:bg-gold-600 text-white font-semibold rounded-xl"
              >
                Got it!
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};

// Trading.com Configuration Modal
const TradingComConfigModal: React.FC<{ isOpen: boolean; onClose: () => void }> = ({ isOpen, onClose }) => {
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
            className="fixed bottom-0 left-0 right-0 bg-theme-modal border-t border-theme-divider rounded-t-3xl z-50 max-h-[80vh] overflow-y-auto"
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-theme-primary">
                  Trading.com Integration
                </h2>
                <button onClick={onClose} className="w-10 h-10 rounded-full bg-theme-badge flex items-center justify-center">
                  <X className="w-5 h-5 text-theme-secondary" />
                </button>
              </div>

              <div className="space-y-4 text-theme-secondary">
                <div className="bg-amber-500/10 border border-amber-500/20 rounded-xl p-4">
                  <div className="flex items-start gap-3">
                    <AlertTriangle className="w-5 h-5 text-amber-500 mt-0.5 flex-shrink-0" />
                    <div>
                      <h3 className="font-semibold text-amber-300 mb-2">
                        API Not Available
                      </h3>
                      <p className="text-sm text-amber-400/70">
                        Trading.com is a forex/CFD broker that does not expose a public API 
                        for fetching market quotes. Their price data is only available through 
                        their proprietary trading platforms (MT5, WebTrader).
                      </p>
                    </div>
                  </div>
                </div>

                <div className="bg-blue-500/10 border border-blue-500/20 rounded-xl p-4">
                  <h3 className="font-semibold text-blue-300 mb-2">
                    📝 How to Track Your Portfolio
                  </h3>
                  <ul className="space-y-2 text-sm text-blue-400/70">
                    <li>1. Add your holdings with ticker, quantity, and buy price</li>
                    <li>2. Enter current prices manually using the edit button (✏️)</li>
                    <li>3. Prices are cached for 20 minutes</li>
                    <li>4. Your portfolio value and P/L are calculated automatically</li>
                  </ul>
                </div>

                <div className="bg-theme-badge border border-theme-divider rounded-xl p-4">
                  <h3 className="font-semibold text-theme-secondary mb-2">
                    🔮 Future Integration
                  </h3>
                  <p className="text-sm text-theme-secondary">
                    If trading.com ever provides a public API or developer program, 
                    we will update this feature to fetch prices automatically. 
                    For now, manual entry ensures accuracy and control.
                  </p>
                </div>
              </div>

              <button
                onClick={onClose}
                className="w-full mt-6 py-4 bg-gold-500 hover:bg-gold-600 text-white font-semibold rounded-xl"
              >
                Understood
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
