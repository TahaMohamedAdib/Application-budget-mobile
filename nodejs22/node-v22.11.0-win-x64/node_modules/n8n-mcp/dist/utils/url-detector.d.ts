import { Request } from 'express';
export declare function detectBaseUrl(req: Request | null, host: string, port: number): string;
export declare function getStartupBaseUrl(host: string, port: number): string;
export declare function formatEndpointUrls(baseUrl: string): {
    health: string;
    mcp: string;
    root: string;
};
//# sourceMappingURL=url-detector.d.ts.map