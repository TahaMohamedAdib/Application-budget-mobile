export interface NodeSourceInfo {
    nodeType: string;
    sourceCode: string;
    credentialCode?: string;
    packageInfo?: any;
    location: string;
}
export declare class NodeSourceExtractor {
    private n8nBasePaths;
    extractNodeSource(nodeType: string): Promise<NodeSourceInfo>;
    private parseNodeType;
    private searchNodeInPath;
    private searchInPnpm;
    private searchWithGlobPattern;
    private tryLoadNodeFile;
    listAvailableNodes(category?: string, search?: string): Promise<any[]>;
    private scanDirectoryForNodes;
    private scanPnpmDirectory;
    extractAIAgentNode(): Promise<NodeSourceInfo>;
}
//# sourceMappingURL=node-source-extractor.d.ts.map