export declare class TelemetryRateLimiter {
    private eventTimestamps;
    private windowMs;
    private maxEvents;
    private droppedEventsCount;
    private lastWarningTime;
    private readonly WARNING_INTERVAL;
    private readonly MAX_ARRAY_SIZE;
    constructor(windowMs?: number, maxEvents?: number);
    allow(): boolean;
    wouldAllow(): boolean;
    getStats(): {
        currentEvents: number;
        maxEvents: number;
        windowMs: number;
        droppedEvents: number;
        utilizationPercent: number;
        remainingCapacity: number;
        arraySize: number;
        maxArraySize: number;
        memoryUsagePercent: number;
    };
    reset(): void;
    private cleanupOldTimestamps;
    private handleRateLimitHit;
    getDroppedEventsCount(): number;
    getTimeUntilCapacity(): number;
    updateLimits(windowMs?: number, maxEvents?: number): void;
}
//# sourceMappingURL=rate-limiter.d.ts.map