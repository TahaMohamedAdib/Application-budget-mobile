import { TelemetryEvent, WorkflowTelemetry, WorkflowMutationRecord } from './telemetry-types';
export declare class TelemetryEventTracker {
    private getUserId;
    private isEnabled;
    private rateLimiter;
    private validator;
    private eventQueue;
    private workflowQueue;
    private mutationQueue;
    private previousTool?;
    private previousToolTimestamp;
    private performanceMetrics;
    constructor(getUserId: () => string, isEnabled: () => boolean);
    trackToolUsage(toolName: string, success: boolean, duration?: number): void;
    trackWorkflowCreation(workflow: any, validationPassed: boolean): Promise<void>;
    trackError(errorType: string, context: string, toolName?: string, errorMessage?: string): void;
    trackEvent(eventName: string, properties: Record<string, any>, checkRateLimit?: boolean): void;
    trackSessionStart(startupData?: {
        durationMs?: number;
        checkpoints?: string[];
        errorCount?: number;
    }): void;
    trackStartupComplete(): void;
    private detectCloudPlatform;
    trackSearchQuery(query: string, resultsFound: number, searchType: string): void;
    trackValidationDetails(nodeType: string, errorType: string, details: Record<string, any>): void;
    trackToolSequence(previousTool: string, currentTool: string, timeDelta: number): void;
    trackNodeConfiguration(nodeType: string, propertiesSet: number, usedDefaults: boolean): void;
    trackPerformanceMetric(operation: string, duration: number, metadata?: Record<string, any>): void;
    updateToolSequence(toolName: string): void;
    getEventQueue(): TelemetryEvent[];
    getWorkflowQueue(): WorkflowTelemetry[];
    getMutationQueue(): WorkflowMutationRecord[];
    clearEventQueue(): void;
    clearWorkflowQueue(): void;
    clearMutationQueue(): void;
    enqueueMutation(mutation: WorkflowMutationRecord): void;
    getMutationQueueSize(): number;
    getStats(): {
        rateLimiter: {
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
        validator: {
            errors: number;
            successes: number;
            total: number;
            errorRate: number;
        };
        eventQueueSize: number;
        workflowQueueSize: number;
        mutationQueueSize: number;
        performanceMetrics: Record<string, any>;
    };
    private recordPerformanceMetric;
    private getPerformanceStats;
    private categorizeError;
    private categorizeConfigComplexity;
    private getPackageVersion;
    private sanitizeErrorType;
    private sanitizeContext;
    private sanitizeErrorMessage;
}
//# sourceMappingURL=event-tracker.d.ts.map