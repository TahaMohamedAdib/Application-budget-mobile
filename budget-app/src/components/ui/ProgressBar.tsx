import React from 'react';
import { motion } from 'framer-motion';

interface ProgressBarProps {
  progress: number;
  color?: string;
  height?: number;
  showLabel?: boolean;
  className?: string;
}

export const ProgressBar: React.FC<ProgressBarProps> = ({
  progress,
  color = '#B8860B',
  height = 8,
  showLabel = false,
  className = '',
}) => {
  const clampedProgress = Math.min(100, Math.max(0, progress));

  return (
    <div className={`w-full ${className}`}>
      <div
        className="w-full bg-gray-200 rounded-full overflow-hidden"
        style={{ height }}
      >
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${clampedProgress}%` }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          className="h-full rounded-full"
          style={{ backgroundColor: color }}
        />
      </div>
      {showLabel && (
        <p className="text-xs text-gray-500 mt-1 text-right">{clampedProgress}%</p>
      )}
    </div>
  );
};
