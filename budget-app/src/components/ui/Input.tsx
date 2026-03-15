import React from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  icon?: React.ReactNode;
}

export const Input: React.FC<InputProps> = ({
  label,
  error,
  icon,
  className = '',
  ...props
}) => {
  return (
    <div className="w-full">
      {label && (
        <label className="block text-sm font-medium text-theme-primary mb-2">
          {label}
        </label>
      )}
      <div className="relative">
        {icon && (
          <div className="absolute left-4 top-1/2 -translate-y-1/2 text-theme-tertiary">
            {icon}
          </div>
        )}
        <input
          className={`w-full px-4 py-3 rounded-xl border border-theme-input-border bg-theme-input-bg text-theme-primary
            placeholder:text-theme focus:outline-none focus:ring-2 focus:ring-gold-500
            focus:border-transparent transition-all duration-200
            ${icon ? 'pl-12' : ''}
            ${error ? 'border-red-500 focus:ring-red-500' : ''}
            ${className}`}
          {...props}
        />
      </div>
      {error && <p className="mt-1 text-sm text-red-500">{error}</p>}
    </div>
  );
};
