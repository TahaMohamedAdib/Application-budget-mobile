export declare class MCPError extends Error {
    code: string;
    statusCode?: number;
    data?: any;
    constructor(message: string, code: string, statusCode?: number, data?: any);
}
export declare class N8NConnectionError extends MCPError {
    constructor(message: string, data?: any);
}
export declare class AuthenticationError extends MCPError {
    constructor(message?: string);
}
export declare class ValidationError extends MCPError {
    constructor(message: string, data?: any);
}
export declare class ToolNotFoundError extends MCPError {
    constructor(toolName: string);
}
export declare class ResourceNotFoundError extends MCPError {
    constructor(resourceUri: string);
}
export declare function handleError(error: any): MCPError;
export declare function withErrorHandling<T>(operation: () => Promise<T>, context: string): Promise<T>;
//# sourceMappingURL=error-handler.d.ts.map