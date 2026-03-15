#!/usr/bin/env node
export declare function loadAuthToken(): string | null;
export declare function startFixedHTTPServer(): Promise<void>;
declare module './mcp/server' {
    interface N8NDocumentationMCPServer {
        executeTool(name: string, args: any): Promise<any>;
    }
}
//# sourceMappingURL=http-server.d.ts.map