import React, { useEffect } from 'react';
import { useStore } from '../store/useStore';
import { ThemeMode } from '../types';

interface ThemeProviderProps {
  children: React.ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const { settings } = useStore();
  const theme = settings.theme;

  useEffect(() => {
    const root = window.document.documentElement;
    
    const applyTheme = (isDark: boolean) => {
      if (isDark) {
        root.classList.add('dark');
      } else {
        root.classList.remove('dark');
      }
    };

    if (theme === 'system') {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      applyTheme(mediaQuery.matches);

      const handler = (e: MediaQueryListEvent) => applyTheme(e.matches);
      mediaQuery.addEventListener('change', handler);
      
      return () => mediaQuery.removeEventListener('change', handler);
    } else {
      applyTheme(theme === 'dark');
    }
  }, [theme]);

  return <>{children}</>;
};

export const useTheme = () => {
  const { settings, updateSettings } = useStore();
  
  const setTheme = (theme: ThemeMode) => {
    updateSettings({ theme });
  };

  const isDark = () => {
    if (settings.theme === 'system') {
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }
    return settings.theme === 'dark';
  };

  return {
    theme: settings.theme,
    setTheme,
    isDark: isDark(),
  };
};
