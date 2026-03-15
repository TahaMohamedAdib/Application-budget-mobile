"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TelemetryRateLimiter = void 0;
const telemetry_types_1 = require("./telemetry-types");
const logger_1 = require("../utils/logger");
class TelemetryRateLimiter {
    constructor(windowMs = telemetry_types_1.TELEMETRY_CONFIG.RATE_LIMIT_WINDOW, maxEvents = telemetry_types_1.TELEMETRY_CONFIG.RATE_LIMIT_MAX_EVENTS) {
        this.eventTimestamps = [];
        this.droppedEventsCount = 0;
        this.lastWarningTime = 0;
        this.WARNING_INTERVAL = 60000;
        this.MAX_ARRAY_SIZE = 1000;
        this.windowMs = windowMs;
        this.maxEvents = maxEvents;
    }
    allow() {
        const now = Date.now();
        this.cleanupOldTimestamps(now);
        if (this.eventTimestamps.length >= this.maxEvents) {
            this.handleRateLimitHit(now);
            return false;
        }
        this.eventTimestamps.push(now);
        return true;
    }
    wouldAllow() {
        const now = Date.now();
        this.cleanupOldTimestamps(now);
        return this.eventTimestamps.length < this.maxEvents;
    }
    getStats() {
        const now = Date.now();
        this.cleanupOldTimestamps(now);
        return {
            currentEvents: this.eventTimestamps.length,
            maxEvents: this.maxEvents,
            windowMs: this.windowMs,
            droppedEvents: this.droppedEventsCount,
            utilizationPercent: Math.round((this.eventTimestamps.length / this.maxEvents) * 100),
            remainingCapacity: Math.max(0, this.maxEvents - this.eventTimestamps.length),
            arraySize: this.eventTimestamps.length,
            maxArraySize: this.MAX_ARRAY_SIZE,
            memoryUsagePercent: Math.round((this.eventTimestamps.length / this.MAX_ARRAY_SIZE) * 100)
        };
    }
    reset() {
        this.eventTimestamps = [];
        this.droppedEventsCount = 0;
        this.lastWarningTime = 0;
    }
    cleanupOldTimestamps(now) {
        const windowStart = now - this.windowMs;
        let i = 0;
        while (i < this.eventTimestamps.length && this.eventTimestamps[i] < windowStart) {
            i++;
        }
        if (i > 0) {
            this.eventTimestamps.splice(0, i);
        }
        if (this.eventTimestamps.length > this.MAX_ARRAY_SIZE) {
            const excess = this.eventTimestamps.length - this.MAX_ARRAY_SIZE;
            this.eventTimestamps.splice(0, excess);
            if (now - this.lastWarningTime > this.WARNING_INTERVAL) {
                logger_1.logger.debug(`Telemetry rate limiter array trimmed: removed ${excess} oldest timestamps to prevent memory leak. ` +
                    `Array size: ${this.eventTimestamps.length}/${this.MAX_ARRAY_SIZE}`);
                this.lastWarningTime = now;
            }
        }
    }
    handleRateLimitHit(now) {
        this.droppedEventsCount++;
        if (now - this.lastWarningTime > this.WARNING_INTERVAL) {
            const stats = this.getStats();
            logger_1.logger.debug(`Telemetry rate limit reached: ${stats.currentEvents}/${stats.maxEvents} events in ${stats.windowMs}ms window. ` +
                `Total dropped: ${stats.droppedEvents}`);
            this.lastWarningTime = now;
        }
    }
    getDroppedEventsCount() {
        return this.droppedEventsCount;
    }
    getTimeUntilCapacity() {
        const now = Date.now();
        this.cleanupOldTimestamps(now);
        if (this.eventTimestamps.length < this.maxEvents) {
            return 0;
        }
        const oldestRelevant = this.eventTimestamps[this.eventTimestamps.length - this.maxEvents];
        const timeUntilExpiry = Math.max(0, (oldestRelevant + this.windowMs) - now);
        return timeUntilExpiry;
    }
    updateLimits(windowMs, maxEvents) {
        if (windowMs !== undefined && windowMs > 0) {
            this.windowMs = windowMs;
        }
        if (maxEvents !== undefined && maxEvents > 0) {
            this.maxEvents = maxEvents;
        }
        logger_1.logger.debug(`Rate limiter updated: ${this.maxEvents} events per ${this.windowMs}ms`);
    }
}
exports.TelemetryRateLimiter = TelemetryRateLimiter;
//# sourceMappingURL=rate-limiter.js.map