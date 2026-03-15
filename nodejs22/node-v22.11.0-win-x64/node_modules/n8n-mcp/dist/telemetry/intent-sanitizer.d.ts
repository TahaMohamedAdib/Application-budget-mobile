export declare class IntentSanitizer {
    sanitize(intent: string): string;
    containsPII(intent: string): boolean;
    detectPIITypes(intent: string): string[];
    truncate(intent: string, maxLength?: number): string;
    isSafeForTelemetry(intent: string): boolean;
}
export declare const intentSanitizer: IntentSanitizer;
//# sourceMappingURL=intent-sanitizer.d.ts.map