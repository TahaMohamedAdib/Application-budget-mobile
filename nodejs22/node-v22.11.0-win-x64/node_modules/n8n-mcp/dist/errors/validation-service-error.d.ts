export declare class ValidationServiceError extends Error {
    readonly nodeType?: string | undefined;
    readonly property?: string | undefined;
    readonly cause?: Error | undefined;
    constructor(message: string, nodeType?: string | undefined, property?: string | undefined, cause?: Error | undefined);
    static jsonParseError(nodeType: string, cause: Error): ValidationServiceError;
    static nodeNotFound(nodeType: string): ValidationServiceError;
    static dataExtractionError(nodeType: string, dataType: string, cause?: Error): ValidationServiceError;
}
//# sourceMappingURL=validation-service-error.d.ts.map