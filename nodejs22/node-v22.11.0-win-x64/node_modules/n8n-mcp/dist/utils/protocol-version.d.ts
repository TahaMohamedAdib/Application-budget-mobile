export interface ClientInfo {
    name?: string;
    version?: string;
    [key: string]: any;
}
export interface ProtocolNegotiationResult {
    version: string;
    isN8nClient: boolean;
    reasoning: string;
}
export declare const STANDARD_PROTOCOL_VERSION = "2025-03-26";
export declare const N8N_PROTOCOL_VERSION = "2024-11-05";
export declare const SUPPORTED_VERSIONS: string[];
export declare function isN8nClient(clientInfo?: ClientInfo, userAgent?: string, headers?: Record<string, string | string[] | undefined>): boolean;
export declare function negotiateProtocolVersion(clientRequestedVersion?: string, clientInfo?: ClientInfo, userAgent?: string, headers?: Record<string, string | string[] | undefined>): ProtocolNegotiationResult;
export declare function isVersionSupported(version: string): boolean;
export declare function getCompatibleVersion(targetVersion?: string): string;
export declare function logProtocolNegotiation(result: ProtocolNegotiationResult, logger: any, context?: string): void;
//# sourceMappingURL=protocol-version.d.ts.map