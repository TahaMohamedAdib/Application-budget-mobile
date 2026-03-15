import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { TrendingUp, TrendingDown, Plus, RefreshCw, Clock, Trash2, ChevronRight, Lock } from 'lucide-react';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { StockHolding } from '../../types';
import { AddHoldingModal } from '../modals/AddHoldingModal';
import { VipUpgradeModal } from '../modals/VipUpgradeModal';

interface PortfolioSectionProps {
  onHoldingClick?: (holding: StockHolding) => void;
}

export const PortfolioSection: React.FC<PortfolioSectionProps> = ({ onHoldingClick }) => {
  const { portfolio, settings, getPortfolioValue, getPortfolioPL, isVip, updateHoldingPrice, deleteHolding } = useStore();
  const [showAddModal, setShowAddModal] = useState(false);
  const [showVipModal, setShowVipModal] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const vip = isVip();
  const totalValue = getPortfolioValue();
  const totalPL = getPortfolioPL();
  const plPercent = totalValue > 0 ? ((totalPL / (totalValue - totalPL)) * 100) : 0;

  const handleAddHolding = () => {
    if (vip) {
      setShowAddModal(true);
    } else {
      setShowVipModal(true);
    }
  };

  const handleRefreshPrices = async () => {
    if (!vip) {
      setShowVipModal(true);
      return;
    }

    setRefreshing(true);
    
    // Simulate fetching delayed quotes from trading.com
    // In production, this would call the actual API
    for (const holding of portfolio) {
      const lastUpdated = new Date(holding.lastUpdated);
      const now = new Date();
      const minutesSinceUpdate = (now.getTime() - lastUpdated.getTime()) / (1000 * 60);
      
      // Only refresh if last updated > 20 minutes
      if (minutesSinceUpdate > 20) {
        // Simulate price change (in production, fetch from trading.com)
        const priceChange = (Math.random() - 0.5) * 0.1; // ±5% change
        const newPrice = holding.currentPrice * (1 + priceChange);
        updateHoldingPrice(holding.id, Math.round(newPrice * 100) / 100);
      }
    }
    
    setTimeout(() => setRefreshing(false), 1000);
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

  // Locked state for non-VIP users
  if (!vip && portfolio.length === 0) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-theme-primary flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-gold-500" />
            Portfolio (Compte Titres)
          </h3>
          <Lock className="w-5 h-5 text-amber-500" />
        </div>
        
        <div className="text-center py-6">
          <div className="w-16 h-16 bg-amber-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <TrendingUp className="w-8 h-8 text-amber-500" />
          </div>
          <p className="text-theme-secondary mb-2">Track your stock portfolio</p>
          <p className="text-sm text-theme-tertiary mb-4">VIP feature • Real-time delayed quotes</p>
          <button
            onClick={() => setShowVipModal(true)}
            className="px-6 py-2 bg-amber-500 text-white rounded-lg font-medium"
          >
            Unlock with VIP
          </button>
        </div>

        <VipUpgradeModal
          isOpen={showVipModal}
          onClose={() => setShowVipModal(false)}
          feature="portfolio"
        />
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4"
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-theme-primary flex items-center gap-2">
          <TrendingUp className="w-5 h-5 text-gold-500" />
          Portfolio (Compte Titres)
        </h3>
        <div className="flex items-center gap-2">
          <button
            onClick={handleRefreshPrices}
            disabled={refreshing}
            className="w-8 h-8 rounded-full bg-theme-badge flex items-center justify-center"
          >
            <RefreshCw className={`w-4 h-4 text-theme-secondary ${refreshing ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={handleAddHolding}
            className="w-8 h-8 rounded-full bg-gold-500 flex items-center justify-center"
          >
            <Plus className="w-4 h-4 text-theme-primary" />
          </button>
        </div>
      </div>

      {/* Summary Card */}
      <div className="bg-theme-surface/50 border border-theme-divider rounded-xl p-4 mb-4">
        <div className="flex justify-between items-start mb-2">
          <div>
            <p className="text-sm text-theme-tertiary">Total Value</p>
            <p className="text-2xl font-bold text-theme-primary">
              {formatCurrency(totalValue, settings.currency)}
            </p>
          </div>
          <div className={`flex items-center gap-1 px-2 py-1 rounded-lg ${totalPL >= 0 ? 'bg-emerald-500/10' : 'bg-red-500/10'}`}>
            {totalPL >= 0 ? (
              <TrendingUp className="w-4 h-4 text-emerald-500" />
            ) : (
              <TrendingDown className="w-4 h-4 text-red-500" />
            )}
            <span className={`text-sm font-medium ${totalPL >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
              {totalPL >= 0 ? '+' : ''}{formatCurrency(totalPL, settings.currency)} ({plPercent.toFixed(1)}%)
            </span>
          </div>
        </div>
        
        {/* Delayed quote notice */}
        <div className="flex items-center gap-1 text-xs text-theme-tertiary">
          <Clock className="w-3 h-3" />
          <span>Prices delayed ~20 min • Last updated: {getLastUpdatedText()}</span>
        </div>
      </div>

      {/* Holdings List */}
      <div className="space-y-2">
        <AnimatePresence>
          {portfolio.map((holding) => {
            const value = holding.quantity * holding.currentPrice;
            const cost = holding.quantity * holding.buyPrice;
            const pl = value - cost;
            const plPct = cost > 0 ? ((pl / cost) * 100) : 0;
            
            return (
              <motion.div
                key={holding.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 20 }}
                onClick={() => onHoldingClick?.(holding)}
                className="flex items-center justify-between p-3 bg-theme-surface/50 border border-theme-divider rounded-xl cursor-pointer hover:bg-theme-surface-hover"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-blue-500/10 rounded-lg flex items-center justify-center">
                    <span className="text-sm font-bold text-blue-500">{holding.ticker.slice(0, 2)}</span>
                  </div>
                  <div>
                    <p className="font-medium text-theme-primary">{holding.ticker}</p>
                    <p className="text-xs text-theme-tertiary">{holding.quantity} shares @ {formatCurrency(holding.currentPrice, settings.currency)}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="text-right">
                    <p className="font-medium text-theme-primary">{formatCurrency(value, settings.currency)}</p>
                    <p className={`text-xs ${pl >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
                      {pl >= 0 ? '+' : ''}{formatCurrency(pl, settings.currency)} ({plPct.toFixed(1)}%)
                    </p>
                  </div>
                  <button
                    onClick={(e) => handleDeleteHolding(holding.id, e)}
                    className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-theme-surface-hover"
                  >
                    <Trash2 className="w-4 h-4 text-gray-400 hover:text-red-500" />
                  </button>
                  <ChevronRight className="w-4 h-4 text-gray-400" />
                </div>
              </motion.div>
            );
          })}
        </AnimatePresence>

        {portfolio.length === 0 && (
          <div className="text-center py-6">
            <p className="text-theme-tertiary mb-2">No holdings yet</p>
            <button
              onClick={handleAddHolding}
              className="text-gold-500 font-medium"
            >
              Add your first stock
            </button>
          </div>
        )}
      </div>

      {/* Modals */}
      <AddHoldingModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
      />

      <VipUpgradeModal
        isOpen={showVipModal}
        onClose={() => setShowVipModal(false)}
        feature="portfolio"
      />
    </motion.div>
  );
};
