"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TelemetryPerformanceMonitor = void 0;
const logger_1 = require("../utils/logger");
class TelemetryPerformanceMonitor {
    constructor() {
        this.metrics = [];
        this.operationTimers = new Map();
        this.maxMetrics = 1000;
        this.startupTime = Date.now();
        this.operationCounts = new Map();
    }
    startOperation(operation) {
        this.operationTimers.set(operation, performance.now());
    }
    endOperation(operation) {
        const startTime = this.operationTimers.get(operation);
        if (!startTime) {
            logger_1.logger.debug(`No start time found for operation: ${operation}`);
            return 0;
        }
        const duration = performance.now() - startTime;
        this.operationTimers.delete(operation);
        const metric = {
            operation,
            duration,
            timestamp: Date.now(),
            memory: this.captureMemoryUsage()
        };
        this.recordMetric(metric);
        const count = this.operationCounts.get(operation) || 0;
        this.operationCounts.set(operation, count + 1);
        return duration;
    }
    recordMetric(metric) {
        this.metrics.push(metric);
        if (this.metrics.length > this.maxMetrics) {
            this.metrics.shift();
        }
        if (metric.duration > 100) {
            logger_1.logger.debug(`Slow telemetry operation: ${metric.operation} took ${metric.duration.toFixed(2)}ms`);
        }
    }
    captureMemoryUsage() {
        if (typeof process !== 'undefined' && process.memoryUsage) {
            const usage = process.memoryUsage();
            return {
                heapUsed: Math.round(usage.heapUsed / 1024 / 1024),
                heapTotal: Math.round(usage.heapTotal / 1024 / 1024),
                external: Math.round(usage.external / 1024 / 1024)
            };
        }
        return undefined;
    }
    getStatistics() {
        const now = Date.now();
        const recentMetrics = this.metrics.filter(m => now - m.timestamp < 60000);
        if (recentMetrics.length === 0) {
            return {
                totalOperations: 0,
                averageDuration: 0,
                slowOperations: 0,
                operationsByType: {},
                memoryUsage: this.captureMemoryUsage(),
                uptimeMs: now - this.startupTime,
                overhead: {
                    percentage: 0,
                    totalMs: 0
                }
            };
        }
        const durations = recentMetrics.map(m => m.duration);
        const totalDuration = durations.reduce((a, b) => a + b, 0);
        const avgDuration = totalDuration / durations.length;
        const slowOps = durations.filter(d => d > 50).length;
        const operationsByType = {};
        const typeGroups = new Map();
        for (const metric of recentMetrics) {
            const type = metric.operation;
            if (!typeGroups.has(type)) {
                typeGroups.set(type, []);
            }
            typeGroups.get(type).push(metric.duration);
        }
        for (const [type, durations] of typeGroups.entries()) {
            const sum = durations.reduce((a, b) => a + b, 0);
            operationsByType[type] = {
                count: durations.length,
                avgDuration: Math.round(sum / durations.length * 100) / 100
            };
        }
        const estimatedOverheadPercentage = Math.min(5, avgDuration / 10);
        return {
            totalOperations: this.operationCounts.size,
            operationsInLastMinute: recentMetrics.length,
            averageDuration: Math.round(avgDuration * 100) / 100,
            slowOperations: slowOps,
            operationsByType,
            memoryUsage: this.captureMemoryUsage(),
            uptimeMs: now - this.startupTime,
            overhead: {
                percentage: estimatedOverheadPercentage,
                totalMs: totalDuration
            }
        };
    }
    getDetailedReport() {
        const stats = this.getStatistics();
        const percentiles = this.calculatePercentiles();
        return {
            summary: stats,
            percentiles,
            topSlowOperations: this.getTopSlowOperations(5),
            memoryTrend: this.getMemoryTrend(),
            recommendations: this.generateRecommendations(stats, percentiles)
        };
    }
    calculatePercentiles() {
        const recentDurations = this.metrics
            .filter(m => Date.now() - m.timestamp < 60000)
            .map(m => m.duration)
            .sort((a, b) => a - b);
        if (recentDurations.length === 0) {
            return { p50: 0, p75: 0, p90: 0, p95: 0, p99: 0 };
        }
        return {
            p50: this.percentile(recentDurations, 0.5),
            p75: this.percentile(recentDurations, 0.75),
            p90: this.percentile(recentDurations, 0.9),
            p95: this.percentile(recentDurations, 0.95),
            p99: this.percentile(recentDurations, 0.99)
        };
    }
    percentile(sorted, p) {
        const index = Math.ceil(sorted.length * p) - 1;
        return Math.round(sorted[Math.max(0, index)] * 100) / 100;
    }
    getTopSlowOperations(n) {
        return [...this.metrics]
            .sort((a, b) => b.duration - a.duration)
            .slice(0, n)
            .map(m => ({
            operation: m.operation,
            duration: Math.round(m.duration * 100) / 100,
            timestamp: m.timestamp
        }));
    }
    getMemoryTrend() {
        const metricsWithMemory = this.metrics.filter(m => m.memory);
        if (metricsWithMemory.length < 2) {
            return { trend: 'stable', delta: 0 };
        }
        const recent = metricsWithMemory.slice(-10);
        const first = recent[0].memory;
        const last = recent[recent.length - 1].memory;
        const delta = last.heapUsed - first.heapUsed;
        let trend;
        if (delta > 5)
            trend = 'increasing';
        else if (delta < -5)
            trend = 'decreasing';
        else
            trend = 'stable';
        return { trend, delta };
    }
    generateRecommendations(stats, percentiles) {
        const recommendations = [];
        if (stats.averageDuration > 50) {
            recommendations.push('Consider batching more events to reduce overhead');
        }
        if (stats.slowOperations > stats.operationsInLastMinute * 0.1) {
            recommendations.push('Many slow operations detected - investigate network latency');
        }
        if (percentiles.p99 > 200) {
            recommendations.push('P99 latency is high - consider implementing local queue persistence');
        }
        const memoryTrend = this.getMemoryTrend();
        if (memoryTrend.trend === 'increasing' && memoryTrend.delta > 10) {
            recommendations.push('Memory usage is increasing - check for memory leaks');
        }
        if (stats.operationsInLastMinute > 1000) {
            recommendations.push('High telemetry volume - ensure rate limiting is effective');
        }
        return recommendations;
    }
    reset() {
        this.metrics = [];
        this.operationTimers.clear();
        this.operationCounts.clear();
        this.startupTime = Date.now();
    }
    getTelemetryOverhead() {
        const stats = this.getStatistics();
        const percentage = stats.overhead.percentage;
        let impact;
        if (percentage < 1)
            impact = 'minimal';
        else if (percentage < 3)
            impact = 'low';
        else if (percentage < 5)
            impact = 'moderate';
        else
            impact = 'high';
        return { percentage, impact };
    }
}
exports.TelemetryPerformanceMonitor = TelemetryPerformanceMonitor;
//# sourceMappingURL=performance-monitor.js.map