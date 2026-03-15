import { Currency } from '../types';

const currencySymbols: Record<Currency, string> = {
  USD: '$',
  EUR: '€',
  GBP: '£',
  CAD: 'C$',
  AUD: 'A$',
};

export const formatCurrency = (amount: number, currency: Currency = 'USD'): string => {
  const symbol = currencySymbols[currency];
  const formatted = Math.abs(amount).toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return amount < 0 ? `-${symbol}${formatted}` : `${symbol}${formatted}`;
};

export const formatCompactCurrency = (amount: number, currency: Currency = 'USD'): string => {
  const symbol = currencySymbols[currency];
  if (Math.abs(amount) >= 1000000) {
    return `${symbol}${(amount / 1000000).toFixed(1)}M`;
  }
  if (Math.abs(amount) >= 1000) {
    return `${symbol}${(amount / 1000).toFixed(1)}K`;
  }
  return `${symbol}${amount.toFixed(0)}`;
};

export const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  });
};

export const formatFullDate = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

export const getCurrentMonth = (): string => {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
};

export const getDaysRemainingInMonth = (): number => {
  const now = new Date();
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  return daysInMonth - now.getDate() + 1;
};

export const getMonthName = (monthString: string): string => {
  const [year, month] = monthString.split('-');
  const date = new Date(parseInt(year), parseInt(month) - 1);
  return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
};

export const getPercentage = (current: number, target: number): number => {
  if (target === 0) return 0;
  return Math.min(100, Math.round((current / target) * 100));
};
