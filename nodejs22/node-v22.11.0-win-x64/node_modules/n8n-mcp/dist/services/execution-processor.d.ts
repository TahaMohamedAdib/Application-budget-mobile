import { Execution, ExecutionPreview, ExecutionRecommendation, ExecutionFilterOptions, FilteredExecutionResponse, Workflow } from '../types/n8n-api';
export declare function generatePreview(execution: Execution): {
    preview: ExecutionPreview;
    recommendation: ExecutionRecommendation;
};
export declare function filterExecutionData(execution: Execution, options: ExecutionFilterOptions, workflow?: Workflow): FilteredExecutionResponse;
export declare function processExecution(execution: Execution, options?: ExecutionFilterOptions, workflow?: Workflow): FilteredExecutionResponse | Execution;
//# sourceMappingURL=execution-processor.d.ts.map