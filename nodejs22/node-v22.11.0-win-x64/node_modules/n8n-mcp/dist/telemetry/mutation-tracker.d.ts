import { WorkflowMutationData, WorkflowMutationRecord } from './mutation-types.js';
export declare class MutationTracker {
    private recentMutations;
    private readonly RECENT_MUTATIONS_LIMIT;
    processMutation(data: WorkflowMutationData, userId: string): Promise<WorkflowMutationRecord | null>;
    private validateMutationData;
    private calculateChangeMetrics;
    private calculateValidationMetrics;
    private extractOperationTypes;
    private addToRecentMutations;
    clearRecentMutations(): void;
    getRecentMutationsCount(): number;
}
export declare const mutationTracker: MutationTracker;
//# sourceMappingURL=mutation-tracker.d.ts.map