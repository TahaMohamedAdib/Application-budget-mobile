import React from 'react';
import { ArrowLeft } from 'lucide-react';
import { PortfolioSectionEnhanced } from '../portfolio/PortfolioSectionEnhanced';

interface PortfolioScreenProps {
  onBack: () => void;
}

export const PortfolioScreen: React.FC<PortfolioScreenProps> = ({ onBack }) => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-theme-from via-theme-via to-theme-to">
      {/* Header */}
      <div className="bg-theme-from/80 backdrop-blur-lg border-b border-theme-divider px-4 pt-12 pb-4 safe-area-top">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-theme-primary" />
          </button>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-theme-primary">Portfolio</h1>
            <p className="text-sm text-theme-secondary">Compte-Titres · Investments</p>
          </div>
        </div>
      </div>

      {/* Portfolio Content */}
      <div className="p-4 pb-24 space-y-4">
        <PortfolioSectionEnhanced />
      </div>
    </div>
  );
};
