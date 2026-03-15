export interface NodeExamples {
    minimal: Record<string, any>;
    common?: Record<string, any>;
    advanced?: Record<string, any>;
}
export declare class ExampleGenerator {
    private static NODE_EXAMPLES;
    static getExamples(nodeType: string, essentials?: any): NodeExamples;
    private static generateBasicExamples;
    private static getDefaultValue;
    private static getStringDefault;
    static getTaskExample(nodeType: string, task: string): Record<string, any> | undefined;
}
//# sourceMappingURL=example-generator.d.ts.map