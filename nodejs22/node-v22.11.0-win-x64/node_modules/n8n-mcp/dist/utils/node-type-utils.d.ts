export declare function normalizeNodeType(type: string): string;
export declare function denormalizeNodeType(type: string, packageType: 'base' | 'langchain'): string;
export declare function extractNodeName(type: string): string;
export declare function getNodePackage(type: string): string | null;
export declare function isBaseNode(type: string): boolean;
export declare function isLangChainNode(type: string): boolean;
export declare function isValidNodeTypeFormat(type: string): boolean;
export declare function getNodeTypeVariations(type: string): string[];
export declare function isTriggerNode(nodeType: string): boolean;
export declare function isActivatableTrigger(nodeType: string): boolean;
export declare function getTriggerTypeDescription(nodeType: string): string;
//# sourceMappingURL=node-type-utils.d.ts.map