import type { NodeClass } from '../types/node-types';
export interface ParsedNode {
    style: 'declarative' | 'programmatic';
    nodeType: string;
    displayName: string;
    description?: string;
    category?: string;
    properties: any[];
    credentials: any[];
    isAITool: boolean;
    isTrigger: boolean;
    isWebhook: boolean;
    operations: any[];
    version?: string;
    isVersioned: boolean;
    packageName: string;
    documentation?: string;
    outputs?: any[];
    outputNames?: string[];
    isToolVariant?: boolean;
    toolVariantOf?: string;
    hasToolVariant?: boolean;
}
export declare class NodeParser {
    private propertyExtractor;
    private currentNodeClass;
    parse(nodeClass: NodeClass, packageName: string): ParsedNode;
    private getNodeDescription;
    private detectStyle;
    private extractNodeType;
    private extractCategory;
    private detectTrigger;
    private detectWebhook;
    private extractVersion;
    private detectVersioned;
    private extractOutputs;
}
//# sourceMappingURL=node-parser.d.ts.map