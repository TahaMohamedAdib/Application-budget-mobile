import { OperationInfo, ApiMethodMapping, CodeExample, TemplateInfo, RelatedResource } from '../utils/enhanced-documentation-fetcher';
interface NodeInfo {
    nodeType: string;
    name: string;
    displayName: string;
    description: string;
    category?: string;
    subcategory?: string;
    icon?: string;
    sourceCode: string;
    credentialCode?: string;
    documentationMarkdown?: string;
    documentationUrl?: string;
    documentationTitle?: string;
    operations?: OperationInfo[];
    apiMethods?: ApiMethodMapping[];
    documentationExamples?: CodeExample[];
    templates?: TemplateInfo[];
    relatedResources?: RelatedResource[];
    requiredScopes?: string[];
    exampleWorkflow?: any;
    exampleParameters?: any;
    propertiesSchema?: any;
    packageName: string;
    version?: string;
    codexData?: any;
    aliases?: string[];
    hasCredentials: boolean;
    isTrigger: boolean;
    isWebhook: boolean;
}
interface SearchOptions {
    query?: string;
    nodeType?: string;
    packageName?: string;
    category?: string;
    hasCredentials?: boolean;
    isTrigger?: boolean;
    limit?: number;
}
export declare class NodeDocumentationService {
    private db;
    private extractor;
    private docsFetcher;
    private dbPath;
    private initialized;
    constructor(dbPath?: string);
    private findDatabasePath;
    private initializeAsync;
    private ensureInitialized;
    private initializeDatabase;
    storeNode(nodeInfo: NodeInfo): Promise<void>;
    getNodeInfo(nodeType: string): Promise<NodeInfo | null>;
    searchNodes(options: SearchOptions): Promise<NodeInfo[]>;
    listNodes(): Promise<NodeInfo[]>;
    rebuildDatabase(): Promise<{
        total: number;
        successful: number;
        failed: number;
        errors: string[];
    }>;
    private parseNodeDefinition;
    private rowToNodeInfo;
    private generateHash;
    private storeStatistics;
    getStatistics(): Promise<any>;
    close(): Promise<void>;
}
export {};
//# sourceMappingURL=node-documentation-service.d.ts.map