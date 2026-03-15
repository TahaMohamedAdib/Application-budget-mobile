import { WorkflowMutationData, MutationDataQualityResult, MutationTrackingOptions } from './mutation-types.js';
export declare const DEFAULT_MUTATION_TRACKING_OPTIONS: Required<MutationTrackingOptions>;
export declare class MutationValidator {
    private options;
    constructor(options?: MutationTrackingOptions);
    validate(data: WorkflowMutationData): MutationDataQualityResult;
    private isValidWorkflow;
    private getWorkflowSizeKb;
    private hasMeaningfulChange;
    hashWorkflow(workflow: any): string;
    shouldExclude(data: WorkflowMutationData): boolean;
    isDuplicate(workflowBefore: any, workflowAfter: any, operations: any[], recentMutations: Array<{
        hashBefore: string;
        hashAfter: string;
        operations: any[];
    }>): boolean;
    private hashOperations;
}
export declare const mutationValidator: MutationValidator;
//# sourceMappingURL=mutation-validator.d.ts.map