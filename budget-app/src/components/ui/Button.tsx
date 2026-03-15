import React from 'react';
import { motion } from 'framer-motion';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  fullWidth?: boolean;
  children: React.ReactNode;
  className?: string;
  disabled?: boolean;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

export const Button: React.FC<ButtonProps> = ({
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  children,
  className = '',
  disabled,
  onClick,
  type = 'button',
}) => {
  const baseStyles = 'font-semibold rounded-2xl transition-all duration-200 flex items-center justify-center gap-2';
  
  const variants = {
    primary: 'bg-gold-500 text-white hover:bg-gold-600 active:bg-gold-700 shadow-lg shadow-gold-500/20',
    secondary: 'bg-theme-badge text-theme-primary hover:bg-theme-surface-hover active:bg-theme-surface',
    ghost: 'bg-transparent text-theme-secondary hover:bg-theme-surface-hover active:bg-theme-surface-hover',
    danger: 'bg-red-500 text-white hover:bg-red-600 active:bg-red-700',
  };
  
  const sizes = {
    sm: 'px-4 py-2 text-sm',
    md: 'px-6 py-3 text-base',
    lg: 'px-8 py-4 text-lg',
  };
  
  const disabledStyles = disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer';
  const widthStyles = fullWidth ? 'w-full' : '';

  return (
    <motion.button
      whileTap={{ scale: disabled ? 1 : 0.98 }}
      className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${disabledStyles} ${widthStyles} ${className}`}
      disabled={disabled}
      onClick={onClick}
      type={type}
    >
      {children}
    </motion.button>
  );
};
