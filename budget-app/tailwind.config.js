/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        gold: {
          50: '#fdf9ed',
          100: '#f9f0ce',
          200: '#f2de9b',
          300: '#e8c85c',
          400: '#d4a520',
          500: '#B8860B',
          600: '#9A6F09',
          700: '#7A5807',
          800: '#5C4205',
          900: '#3E2C03',
        },
        primary: {
          50: '#f8fafc',
          100: '#f1f5f9',
          200: '#e2e8f0',
          300: '#cbd5e1',
          400: '#94a3b8',
          500: '#64748b',
          600: '#475569',
          700: '#334155',
          800: '#1e293b',
          900: '#0f172a',
        },
        accent: {
          50: '#ecfdf5',
          100: '#d1fae5',
          200: '#a7f3d0',
          300: '#6ee7b7',
          400: '#34d399',
          500: '#10b981',
          600: '#059669',
          700: '#047857',
          800: '#065f46',
          900: '#064e3b',
        },
        // Semantic theme colors via CSS variables
        theme: {
          base: 'rgb(var(--color-bg-base) / <alpha-value>)',
          surface: 'rgb(var(--color-surface))',
          'surface-hover': 'rgb(var(--color-surface-hover))',
          'surface-border': 'rgb(var(--color-surface-border))',
          modal: 'rgb(var(--color-modal-bg))',
          'modal-border': 'rgb(var(--color-modal-border))',
          divider: 'rgb(var(--color-divider))',
          badge: 'rgb(var(--color-badge-bg))',
          'input-bg': 'rgb(var(--color-input-bg))',
          'input-border': 'rgb(var(--color-input-border))',
        },
      },
      textColor: {
        theme: {
          primary: 'rgb(var(--color-text-primary))',
          secondary: 'rgb(var(--color-text-secondary))',
          tertiary: 'rgb(var(--color-text-tertiary))',
          inverse: 'rgb(var(--color-text-inverse))',
        },
      },
      placeholderColor: {
        theme: 'rgb(var(--color-input-placeholder))',
      },
      gradientColorStops: {
        'theme-from': 'rgb(var(--color-bg-gradient-from))',
        'theme-via': 'rgb(var(--color-bg-gradient-via))',
        'theme-to': 'rgb(var(--color-bg-gradient-to))',
      },
      boxShadow: {
        'theme-card': 'var(--shadow-card)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
