import { MetadataRequest, MetadataResult } from './metadata-generator';
export interface BatchProcessorOptions {
    apiKey: string;
    model?: string;
    batchSize?: number;
    outputDir?: string;
}
export interface BatchJob {
    id: string;
    status: 'validating' | 'in_progress' | 'finalizing' | 'completed' | 'failed' | 'expired' | 'cancelled';
    created_at: number;
    completed_at?: number;
    input_file_id: string;
    output_file_id?: string;
    error?: any;
}
export declare class BatchProcessor {
    private client;
    private generator;
    private batchSize;
    private outputDir;
    constructor(options: BatchProcessorOptions);
    processTemplates(templates: MetadataRequest[], progressCallback?: (message: string, current: number, total: number) => void): Promise<Map<number, MetadataResult>>;
    private submitBatch;
    private processBatch;
    private createBatches;
    private createBatchFile;
    private uploadFile;
    private createBatchJob;
    private monitorBatchJob;
    private retrieveResults;
    private cleanup;
    private sleep;
}
//# sourceMappingURL=batch-processor.d.ts.map