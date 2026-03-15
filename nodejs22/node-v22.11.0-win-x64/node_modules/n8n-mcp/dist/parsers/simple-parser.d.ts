import type { NodeClass } from '../types/node-types';
export interface ParsedNode {
    style: 'declarative' | 'programmatic';
    nodeType: string;
    displayName: string;
    description?: string;
    category?: string;
    properties: any[];
    credentials: string[];
    isAITool: boolean;
    isTrigger: boolean;
    isWebhook: boolean;
    operations: any[];
    version?: string;
    isVersioned: boolean;
}
export declare class SimpleParser {
    parse(nodeClass: NodeClass): ParsedNode;
    private detectTrigger;
    private extractOperations;
    private extractProgrammaticOperations;
    private extractVersion;
    private isVersionedNode;
}
//# sourceMappingURL=simple-parser.d.ts.map