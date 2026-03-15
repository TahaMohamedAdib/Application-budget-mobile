export interface SanitizerConfig {
    problematicTokens: string[];
    tokenPatterns: RegExp[];
    replacements: Map<string, string>;
}
export declare const defaultSanitizerConfig: SanitizerConfig;
export declare class TemplateSanitizer {
    private config;
    constructor(config?: SanitizerConfig);
    addProblematicToken(token: string): void;
    addTokenPattern(pattern: RegExp, replacement: string): void;
    sanitizeWorkflow(workflow: any): {
        sanitized: any;
        wasModified: boolean;
    };
    needsSanitization(workflow: any): boolean;
    detectTokens(workflow: any): string[];
    private sanitizeObject;
    private replaceTokens;
}
//# sourceMappingURL=template-sanitizer.d.ts.map