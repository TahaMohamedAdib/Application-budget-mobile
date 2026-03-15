export type NodeConfigValue = string | number | boolean | null | undefined | NodeConfig | NodeConfigValue[];
export interface NodeConfig {
    [key: string]: NodeConfigValue;
}
export interface FixedCollectionPattern {
    nodeType: string;
    property: string;
    subProperty?: string;
    expectedStructure: string;
    invalidPatterns: string[];
}
export interface FixedCollectionValidationResult {
    isValid: boolean;
    errors: Array<{
        pattern: string;
        message: string;
        fix: string;
    }>;
    autofix?: NodeConfig | NodeConfigValue[];
}
export declare class FixedCollectionValidator {
    private static isNodeConfig;
    private static getNestedValue;
    private static readonly KNOWN_PATTERNS;
    static validate(nodeType: string, config: NodeConfig): FixedCollectionValidationResult;
    static applyAutofix(config: NodeConfig, pattern: FixedCollectionPattern): NodeConfig | NodeConfigValue[];
    private static normalizeNodeType;
    private static getPatternForNode;
    private static hasInvalidStructure;
    private static generateFixMessage;
    private static generateAutofix;
    static getAllPatterns(): FixedCollectionPattern[];
    static isNodeSusceptible(nodeType: string): boolean;
}
//# sourceMappingURL=fixed-collection-validator.d.ts.map