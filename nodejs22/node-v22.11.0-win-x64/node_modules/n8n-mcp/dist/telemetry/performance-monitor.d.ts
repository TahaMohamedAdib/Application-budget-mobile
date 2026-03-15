export declare class TelemetryPerformanceMonitor {
    private metrics;
    private operationTimers;
    private readonly maxMetrics;
    private startupTime;
    private operationCounts;
    startOperation(operation: string): void;
    endOperation(operation: string): number;
    private recordMetric;
    private captureMemoryUsage;
    getStatistics(): {
        totalOperations: number;
        averageDuration: number;
        slowOperations: number;
        operationsByType: {};
        memoryUsage: {
            heapUsed: number;
            heapTotal: number;
            external: number;
        } | undefined;
        uptimeMs: number;
        overhead: {
            percentage: number;
            totalMs: number;
        };
        operationsInLastMinute?: undefined;
    } | {
        totalOperations: number;
        operationsInLastMinute: number;
        averageDuration: number;
        slowOperations: number;
        operationsByType: Record<string, {
            count: number;
            avgDuration: number;
        }>;
        memoryUsage: {
            heapUsed: number;
            heapTotal: number;
            external: number;
        } | undefined;
        uptimeMs: number;
        overhead: {
            percentage: number;
            totalMs: number;
        };
    };
    getDetailedReport(): {
        summary: {
            totalOperations: number;
            averageDuration: number;
            slowOperations: number;
            operationsByType: {};
            memoryUsage: {
                heapUsed: number;
                heapTotal: number;
                external: number;
            } | undefined;
            uptimeMs: number;
            overhead: {
                percentage: number;
                totalMs: number;
            };
            operationsInLastMinute?: undefined;
        } | {
            totalOperations: number;
            operationsInLastMinute: number;
            averageDuration: number;
            slowOperations: number;
            operationsByType: Record<string, {
                count: number;
                avgDuration: number;
            }>;
            memoryUsage: {
                heapUsed: number;
                heapTotal: number;
                external: number;
            } | undefined;
            uptimeMs: number;
            overhead: {
                percentage: number;
                totalMs: number;
            };
        };
        percentiles: {
            p50: number;
            p75: number;
            p90: number;
            p95: number;
            p99: number;
        };
        topSlowOperations: {
            operation: string;
            duration: number;
            timestamp: number;
        }[];
        memoryTrend: {
            trend: string;
            delta: number;
        };
        recommendations: string[];
    };
    private calculatePercentiles;
    private percentile;
    private getTopSlowOperations;
    private getMemoryTrend;
    private generateRecommendations;
    reset(): void;
    getTelemetryOverhead(): {
        percentage: number;
        impact: 'minimal' | 'low' | 'moderate' | 'high';
    };
}
//# sourceMappingURL=performance-monitor.d.ts.map