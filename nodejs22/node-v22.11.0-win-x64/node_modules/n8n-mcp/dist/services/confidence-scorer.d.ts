export interface ConfidenceScore {
    value: number;
    reason: string;
    factors: ConfidenceFactor[];
}
export interface ConfidenceFactor {
    name: string;
    weight: number;
    matched: boolean;
    description: string;
}
export declare class ConfidenceScorer {
    static scoreResourceLocatorRecommendation(fieldName: string, nodeType: string, value: string): ConfidenceScore;
    private static readonly EXACT_FIELD_MAPPINGS;
    private static checkExactFieldMatch;
    private static readonly FIELD_PATTERNS;
    private static checkFieldPattern;
    private static checkValuePattern;
    private static readonly RESOURCE_HEAVY_NODES;
    private static checkNodeCategory;
    static getConfidenceLevel(score: number): 'high' | 'medium' | 'low' | 'very-low';
    static shouldApplyRecommendation(score: number, threshold?: 'strict' | 'normal' | 'relaxed'): boolean;
}
//# sourceMappingURL=confidence-scorer.d.ts.map