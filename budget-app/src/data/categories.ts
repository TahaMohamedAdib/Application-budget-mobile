import { Category } from '../types';

export const defaultCategories: Category[] = [
  // Fixed
  { id: 'rent', group: 'fixed', name: 'Rent/House', icon: 'Home', color: '#ef4444' },
  { id: 'utilities', group: 'fixed', name: 'Utilities', icon: 'Zap', color: '#f97316' },
  { id: 'phone', group: 'fixed', name: 'Phone/Internet', icon: 'Smartphone', color: '#8b5cf6' },
  { id: 'subscriptions', group: 'fixed', name: 'Subscriptions', icon: 'Tv', color: '#ec4899' },
  { id: 'insurance', group: 'fixed', name: 'Insurance', icon: 'Shield', color: '#06b6d4' },
  { id: 'loans', group: 'fixed', name: 'Loans', icon: 'CreditCard', color: '#64748b' },

  // Variable
  { id: 'groceries', group: 'variable', name: 'Groceries', icon: 'ShoppingCart', color: '#B8860B' },
  { id: 'fuel', group: 'variable', name: 'Fuel/Transport', icon: 'Car', color: '#3b82f6' },
  { id: 'eating-out', group: 'variable', name: 'Eating Out', icon: 'Utensils', color: '#f59e0b' },
  { id: 'shopping', group: 'variable', name: 'Shopping', icon: 'ShoppingBag', color: '#a855f7' },
  { id: 'health', group: 'variable', name: 'Health', icon: 'Heart', color: '#ef4444' },
  { id: 'fun', group: 'variable', name: 'Fun', icon: 'Gamepad2', color: '#B8860B' },
  { id: 'other', group: 'variable', name: 'Other', icon: 'MoreHorizontal', color: '#6b7280' },

  // Future (Sinking funds)
  { id: 'car-repairs', group: 'future', name: 'Car/Repairs', icon: 'Wrench', color: '#f97316' },
  { id: 'gifts', group: 'future', name: 'Gifts', icon: 'Gift', color: '#ec4899' },
  { id: 'vacation', group: 'future', name: 'Vacation', icon: 'Plane', color: '#06b6d4' },
  { id: 'taxes', group: 'future', name: 'Taxes/Fees', icon: 'FileText', color: '#64748b' },
  { id: 'annual-insurance', group: 'future', name: 'Annual Insurance', icon: 'Calendar', color: '#8b5cf6' },

  // Wealth
  { id: 'emergency-fund', group: 'wealth', name: 'Emergency Fund', icon: 'Umbrella', color: '#B8860B' },
  { id: 'investing', group: 'wealth', name: 'Investing', icon: 'TrendingUp', color: '#3b82f6' },
];

export const getCategoryById = (id: string): Category | undefined => {
  return defaultCategories.find((c) => c.id === id);
};

export const getCategoriesByGroup = (group: Category['group']): Category[] => {
  return defaultCategories.filter((c) => c.group === group);
};
