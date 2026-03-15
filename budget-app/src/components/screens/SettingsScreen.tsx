import React from 'react';
import { ArrowLeft, Sun, Moon, Smartphone, ChevronRight, User, Bell, Shield, HelpCircle, LogOut } from 'lucide-react';
import { useTheme } from '../ThemeProvider';
import { useAuth } from '../../lib/AuthContext';
import { ThemeMode } from '../../types';

interface SettingsScreenProps {
  onBack: () => void;
}

export const SettingsScreen: React.FC<SettingsScreenProps> = ({ onBack }) => {
  const { theme, setTheme } = useTheme();
  const { signOut, user } = useAuth();

  const themeOptions: { id: ThemeMode; label: string; icon: React.ElementType }[] = [
    { id: 'light', label: 'Light', icon: Sun },
    { id: 'dark', label: 'Dark', icon: Moon },
    { id: 'system', label: 'System', icon: Smartphone },
  ];

  const menuItems = [
    { icon: User, label: 'Account', onClick: () => alert('Account settings coming soon!') },
    { icon: Bell, label: 'Notifications', onClick: () => alert('Notification settings coming soon!') },
    { icon: Shield, label: 'Privacy', onClick: () => alert('Privacy settings coming soon!') },
    { icon: HelpCircle, label: 'Help & Support', onClick: () => alert('Help & Support coming soon!') },
  ];

  return (
    <div className="min-h-screen overflow-y-auto bg-gradient-to-b from-theme-from via-theme-via to-theme-to transition-colors">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-theme-from/80 backdrop-blur-lg border-b border-theme-divider safe-area-top">
        <div className="flex items-center gap-3 px-4 py-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full bg-theme-surface backdrop-blur-sm border border-theme-surface-border flex items-center justify-center"
          >
            <ArrowLeft className="w-5 h-5 text-theme-primary" />
          </button>
          <h1 className="text-xl font-bold text-theme-primary">Settings</h1>
        </div>
      </div>

      <div className="px-4 space-y-4">
        {/* Theme Selection */}
        <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
          <h3 className="font-semibold text-theme-primary mb-4">Appearance</h3>
          <div className="flex gap-2">
            {themeOptions.map((option) => {
              const Icon = option.icon;
              const isSelected = theme === option.id;
              return (
                <button
                  key={option.id}
                  onClick={() => setTheme(option.id)}
                  className={`flex-1 flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all duration-200 ${
                    isSelected
                      ? 'border-gold-500 bg-gold-500/20'
                      : 'border-theme-divider bg-theme-surface/50'
                  }`}
                >
                  <Icon
                    className={`w-6 h-6 ${
                      isSelected ? 'text-gold-400' : 'text-theme-secondary'
                    }`}
                  />
                  <span
                    className={`text-sm font-medium ${
                      isSelected ? 'text-gold-400' : 'text-theme-secondary'
                    }`}
                  >
                    {option.label}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Menu Items */}
        <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl overflow-hidden">
          {menuItems.map((item, index) => {
            const Icon = item.icon;
            return (
              <button
                key={item.label}
                onClick={item.onClick}
                className={`w-full flex items-center gap-4 p-4 hover:bg-theme-surface-hover transition-colors ${
                  index !== menuItems.length - 1 ? 'border-b border-theme-divider' : ''
                }`}
              >
                <Icon className="w-5 h-5 text-theme-secondary" />
                <span className="flex-1 text-left font-medium text-theme-primary">
                  {item.label}
                </span>
                <ChevronRight className="w-5 h-5 text-theme-tertiary" />
              </button>
            );
          })}
        </div>

        {/* Logout */}
        <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl overflow-hidden">
          <button 
            onClick={() => signOut()}
            className="w-full flex items-center gap-4 p-4 hover:bg-red-500/10 transition-colors"
          >
            <LogOut className="w-5 h-5 text-red-400" />
            <span className="flex-1 text-left font-medium text-red-400">Log Out</span>
          </button>
          {user && (
            <p className="px-4 pb-3 text-xs text-theme-tertiary">{user.email}</p>
          )}
        </div>

        {/* App Version */}
        <p className="text-center text-sm text-theme-tertiary mt-6">
          SafeSpend v1.0.0
        </p>
      </div>
    </div>
  );
};
