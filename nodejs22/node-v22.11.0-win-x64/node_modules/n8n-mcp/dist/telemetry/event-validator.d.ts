import { z } from 'zod';
import { TelemetryEvent, WorkflowTelemetry } from './telemetry-types';
export declare const telemetryEventSchema: z.ZodObject<{
    user_id: z.ZodString;
    event: z.ZodString;
    properties: z.ZodEffects<z.ZodRecord<z.ZodString, z.ZodUnknown>, Record<string, any>, Record<string, unknown>>;
    created_at: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    properties: Record<string, any>;
    event: string;
    user_id: string;
    created_at?: string | undefined;
}, {
    properties: Record<string, unknown>;
    event: string;
    user_id: string;
    created_at?: string | undefined;
}>;
export declare const workflowTelemetrySchema: z.ZodObject<{
    user_id: z.ZodString;
    workflow_hash: z.ZodString;
    node_count: z.ZodNumber;
    node_types: z.ZodArray<z.ZodString, "many">;
    has_trigger: z.ZodBoolean;
    has_webhook: z.ZodBoolean;
    complexity: z.ZodEnum<["simple", "medium", "complex"]>;
    sanitized_workflow: z.ZodObject<{
        nodes: z.ZodArray<z.ZodAny, "many">;
        connections: z.ZodRecord<z.ZodString, z.ZodAny>;
    }, "strip", z.ZodTypeAny, {
        nodes: any[];
        connections: Record<string, any>;
    }, {
        nodes: any[];
        connections: Record<string, any>;
    }>;
    created_at: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    complexity: "simple" | "medium" | "complex";
    user_id: string;
    workflow_hash: string;
    node_count: number;
    node_types: string[];
    has_trigger: boolean;
    has_webhook: boolean;
    sanitized_workflow: {
        nodes: any[];
        connections: Record<string, any>;
    };
    created_at?: string | undefined;
}, {
    complexity: "simple" | "medium" | "complex";
    user_id: string;
    workflow_hash: string;
    node_count: number;
    node_types: string[];
    has_trigger: boolean;
    has_webhook: boolean;
    sanitized_workflow: {
        nodes: any[];
        connections: Record<string, any>;
    };
    created_at?: string | undefined;
}>;
export declare class TelemetryEventValidator {
    private validationErrors;
    private validationSuccesses;
    validateEvent(event: TelemetryEvent): TelemetryEvent | null;
    validateWorkflow(workflow: WorkflowTelemetry): WorkflowTelemetry | null;
    getStats(): {
        errors: number;
        successes: number;
        total: number;
        errorRate: number;
    };
    resetStats(): void;
}
//# sourceMappingURL=event-validator.d.ts.map