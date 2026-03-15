import React from 'react';
import { motion } from 'framer-motion';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
  gradient?: boolean;
}

export const Card: React.FC<CardProps> = ({
  children,
  className = '',
  onClick,
  gradient = false,
}) => {
  const baseStyles = 'rounded-3xl p-5 transition-all duration-200';
  const bgStyles = gradient
    ? 'gradient-primary text-white'
    : 'bg-theme-surface backdrop-blur-xl border border-theme-surface-border shadow-theme-card';
  const clickStyles = onClick ? 'cursor-pointer hover:shadow-md active:scale-[0.99]' : '';

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className={`${baseStyles} ${bgStyles} ${clickStyles} ${className}`}
      onClick={onClick}
    >
      {children}
    </motion.div>
  );
};
