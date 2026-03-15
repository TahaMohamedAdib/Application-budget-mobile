export interface MCPClientConfig {
    serverUrl: string;
    authToken?: string;
    connectionType: 'http' | 'websocket' | 'stdio';
}
export declare class MCPClient {
    private client;
    private config;
    private connected;
    constructor(config: MCPClientConfig);
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    listTools(): Promise<any>;
    callTool(name: string, args: any): Promise<any>;
    listResources(): Promise<any>;
    readResource(uri: string): Promise<any>;
    listPrompts(): Promise<any>;
    getPrompt(name: string, args?: any): Promise<any>;
    private ensureConnected;
}
//# sourceMappingURL=mcp-client.d.ts.map