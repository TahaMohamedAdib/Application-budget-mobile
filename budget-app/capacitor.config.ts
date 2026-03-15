import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.safespend.budgetapp',
  appName: 'SafeSpend',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    url: 'http://10.0.2.2:5173',
    cleartext: true
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '#0F172A',
      showSpinner: false,
      androidSpinnerStyle: 'small',
      spinnerColor: '#10B981'
    },
    StatusBar: {
      style: 'light',
      backgroundColor: '#0F172A'
    }
  },
  ios: {
    contentInset: 'automatic'
  },
  android: {
    allowMixedContent: true
  }
};

export default config;
