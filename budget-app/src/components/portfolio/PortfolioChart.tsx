import React, { useState } from 'react';
import { XAxis, YAxis, Tooltip, ResponsiveContainer, Area, AreaChart } from 'recharts';
import { useStore } from '../../store/useStore';
import { formatCurrency } from '../../utils/formatters';
import { ChartTimeRange } from '../../types';

const timeRanges: ChartTimeRange[] = ['1W', '1M', '3M', '1Y', 'ALL'];

export const PortfolioChart: React.FC = () => {
  const { settings, getPortfolioSnapshots, getPortfolioValue } = useStore();
  const [selectedRange, setSelectedRange] = useState<ChartTimeRange>('1M');

  const snapshots = getPortfolioSnapshots(selectedRange);
  const currentValue = getPortfolioValue();

  // If no snapshots, create a simple one with current value
  const chartData = snapshots.length > 0 
    ? snapshots.map((s) => ({
        date: new Date(s.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
        value: s.totalValue,
      }))
    : [{ date: 'Today', value: currentValue }];

  // Calculate change
  const firstValue = chartData.length > 0 ? chartData[0].value : 0;
  const lastValue = chartData.length > 0 ? chartData[chartData.length - 1].value : currentValue;
  const change = lastValue - firstValue;
  const changePercent = firstValue > 0 ? (change / firstValue) * 100 : 0;
  const isPositive = change >= 0;

  return (
    <div className="bg-theme-surface backdrop-blur-xl border border-theme-surface-border rounded-2xl p-4">
      {/* Chart Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <p className="text-sm text-theme-tertiary">Portfolio Value</p>
          <p className="text-2xl font-bold text-theme-primary">
            {formatCurrency(currentValue, settings.currency)}
          </p>
          <p className={`text-sm ${isPositive ? 'text-emerald-500' : 'text-red-500'}`}>
            {isPositive ? '+' : ''}{formatCurrency(change, settings.currency)} ({changePercent.toFixed(1)}%)
          </p>
        </div>
      </div>

      {/* Time Range Selector */}
      <div className="flex gap-2 mb-4">
        {timeRanges.map((range) => (
          <button
            key={range}
            onClick={() => setSelectedRange(range)}
            className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
              selectedRange === range
                ? 'bg-gold-500 text-white'
                : 'bg-theme-badge text-theme-secondary'
            }`}
          >
            {range}
          </button>
        ))}
      </div>

      {/* Chart */}
      <div className="h-48">
        {chartData.length > 1 ? (
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={isPositive ? '#10B981' : '#ef4444'} stopOpacity={0.3}/>
                  <stop offset="95%" stopColor={isPositive ? '#10B981' : '#ef4444'} stopOpacity={0}/>
                </linearGradient>
              </defs>
              <XAxis 
                dataKey="date" 
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#9ca3af', fontSize: 10 }}
              />
              <YAxis 
                hide 
                domain={['dataMin - 100', 'dataMax + 100']}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#1f2937',
                  border: 'none',
                  borderRadius: '8px',
                  color: '#fff',
                }}
                formatter={(value) => [formatCurrency(value as number, settings.currency), 'Value']}
              />
              <Area
                type="monotone"
                dataKey="value"
                stroke={isPositive ? '#10B981' : '#ef4444'}
                strokeWidth={2}
                fill="url(#colorValue)"
              />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <div className="h-full flex items-center justify-center">
            <p className="text-theme-tertiary text-sm text-center">
              Add investments and check back later<br />to see your portfolio growth
            </p>
          </div>
        )}
      </div>

      {/* Disclaimer */}
      <p className="text-xs text-theme-tertiary mt-2 text-center">
        Prices from trading.com (may be delayed depending on source)
      </p>
    </div>
  );
};
