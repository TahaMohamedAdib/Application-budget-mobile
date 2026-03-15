import React, { useRef, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Calendar, ClipboardList, TrendingUp } from 'lucide-react';

type TabType = 'today' | 'plan' | 'wealth';

interface BottomNavProps {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
}

const tabs: { id: TabType; label: string; icon: React.ElementType }[] = [
  { id: 'today', label: 'Today', icon: Calendar },
  { id: 'plan', label: 'Plan', icon: ClipboardList },
  { id: 'wealth', label: 'Wealth', icon: TrendingUp },
];

export const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onTabChange }) => {
  const touchStartX = useRef(0);
  const isDragging = useRef(false);

  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
    isDragging.current = true;
  }, []);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging.current) return;
    const deltaX = e.touches[0].clientX - touchStartX.current;
    const threshold = 40;
    if (Math.abs(deltaX) > threshold) {
      const currentIndex = tabs.findIndex(t => t.id === activeTab);
      if (deltaX > 0 && currentIndex > 0) {
        onTabChange(tabs[currentIndex - 1].id);
      } else if (deltaX < 0 && currentIndex < tabs.length - 1) {
        onTabChange(tabs[currentIndex + 1].id);
      }
      isDragging.current = false;
    }
  }, [activeTab, onTabChange]);

  const handleTouchEnd = useCallback(() => {
    isDragging.current = false;
  }, []);

  return (
    <nav
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      style={{
        position: 'fixed',
        bottom: '8px',
        left: '8px',
        right: '8px',
        zIndex: 40,
        borderRadius: '26px',
        background: 'rgba(40, 50, 70, 0.55)',
        backdropFilter: 'blur(50px) saturate(180%)',
        WebkitBackdropFilter: 'blur(50px) saturate(180%)',
        border: '0.5px solid rgba(255, 255, 255, 0.15)',
        boxShadow: '0 2px 20px rgba(0, 0, 0, 0.2)',
        paddingBottom: 'env(safe-area-inset-bottom, 0px)',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'stretch',
          padding: '6px',
        }}
      >
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;

          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              style={{
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                flex: 1,
                gap: '3px',
                padding: '8px 0',
                border: 'none',
                background: 'none',
                cursor: 'pointer',
                WebkitTapHighlightColor: 'transparent',
              }}
            >
              {isActive && (
                <motion.div
                  layoutId="navCapsule"
                  style={{
                    position: 'absolute',
                    inset: '0',
                    borderRadius: '20px',
                    background: 'rgba(0, 0, 0, 0.4)',
                    boxShadow: 'inset 0 1.5px 3px rgba(0, 0, 0, 0.35), inset 0 0 0 0.5px rgba(0, 0, 0, 0.1)',
                  }}
                  transition={{
                    type: 'spring',
                    stiffness: 350,
                    damping: 30,
                  }}
                />
              )}
              <Icon
                style={{
                  position: 'relative',
                  zIndex: 1,
                  width: '22px',
                  height: '22px',
                  color: isActive ? '#34d399' : 'rgba(255, 255, 255, 0.45)',
                  transition: 'color 0.2s ease',
                  strokeWidth: 1.8,
                }}
              />
              <span
                style={{
                  position: 'relative',
                  zIndex: 1,
                  fontSize: '10px',
                  lineHeight: 1,
                  fontWeight: 500,
                  color: isActive ? '#34d399' : 'rgba(255, 255, 255, 0.45)',
                  transition: 'color 0.2s ease',
                }}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
