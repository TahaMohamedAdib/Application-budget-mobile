export interface PropertyDependency {
    property: string;
    displayName: string;
    dependsOn: DependencyCondition[];
    showWhen?: Record<string, any>;
    hideWhen?: Record<string, any>;
    enablesProperties?: string[];
    disablesProperties?: string[];
    notes?: string[];
}
export interface DependencyCondition {
    property: string;
    values: any[];
    condition: 'equals' | 'not_equals' | 'includes' | 'not_includes';
    description?: string;
}
export interface DependencyAnalysis {
    totalProperties: number;
    propertiesWithDependencies: number;
    dependencies: PropertyDependency[];
    dependencyGraph: Record<string, string[]>;
    suggestions: string[];
}
export declare class PropertyDependencies {
    static analyze(properties: any[]): DependencyAnalysis;
    private static extractDependency;
    private static generateConditionDescription;
    private static generateSuggestions;
    static getVisibilityImpact(properties: any[], config: Record<string, any>): {
        visible: string[];
        hidden: string[];
        reasons: Record<string, string>;
    };
    private static checkVisibility;
}
//# sourceMappingURL=property-dependencies.d.ts.map