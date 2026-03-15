export interface EnhancedNodeDocumentation {
    markdown: string;
    url: string;
    title?: string;
    description?: string;
    operations?: OperationInfo[];
    apiMethods?: ApiMethodMapping[];
    examples?: CodeExample[];
    templates?: TemplateInfo[];
    relatedResources?: RelatedResource[];
    requiredScopes?: string[];
    metadata?: DocumentationMetadata;
}
export interface OperationInfo {
    resource: string;
    operation: string;
    description: string;
    subOperations?: string[];
}
export interface ApiMethodMapping {
    resource: string;
    operation: string;
    apiMethod: string;
    apiUrl: string;
}
export interface CodeExample {
    title?: string;
    description?: string;
    type: 'json' | 'javascript' | 'yaml' | 'text';
    code: string;
    language?: string;
}
export interface TemplateInfo {
    name: string;
    description?: string;
    url?: string;
}
export interface RelatedResource {
    title: string;
    url: string;
    type: 'documentation' | 'api' | 'tutorial' | 'external';
}
export interface DocumentationMetadata {
    contentType?: string[];
    priority?: string;
    tags?: string[];
    lastUpdated?: Date;
}
export declare class EnhancedDocumentationFetcher {
    private docsPath;
    private readonly docsRepoUrl;
    private cloned;
    constructor(docsPath?: string);
    private sanitizePath;
    ensureDocsRepository(): Promise<void>;
    getEnhancedNodeDocumentation(nodeType: string): Promise<EnhancedNodeDocumentation | null>;
    private parseEnhancedDocumentation;
    private extractFrontmatter;
    private extractTitle;
    private extractDescription;
    private extractOperations;
    private extractApiMethods;
    private extractCodeExamples;
    private extractTemplates;
    private extractRelatedResources;
    private extractRequiredScopes;
    private mapLanguageToType;
    private isCredentialDoc;
    private extractNodeName;
    private searchForNodeDoc;
    private generateDocUrl;
    cleanup(): Promise<void>;
}
//# sourceMappingURL=enhanced-documentation-fetcher.d.ts.map