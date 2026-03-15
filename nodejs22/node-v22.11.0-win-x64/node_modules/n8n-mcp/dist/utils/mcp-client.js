"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MCPClient = void 0;
const index_js_1 = require("@modelcontextprotocol/sdk/client/index.js");
const stdio_js_1 = require("@modelcontextprotocol/sdk/client/stdio.js");
const websocket_js_1 = require("@modelcontextprotocol/sdk/client/websocket.js");
const types_js_1 = require("@modelcontextprotocol/sdk/types.js");
class MCPClient {
    constructor(config) {
        this.connected = false;
        this.config = config;
        this.client = new index_js_1.Client({
            name: 'n8n-mcp-client',
            version: '1.0.0',
        }, {
            capabilities: {},
        });
    }
    async connect() {
        if (this.connected) {
            return;
        }
        let transport;
        switch (this.config.connectionType) {
            case 'websocket':
                const wsUrl = this.config.serverUrl.replace(/^http/, 'ws');
                transport = new websocket_js_1.WebSocketClientTransport(new URL(wsUrl));
                break;
            case 'stdio':
                const [command, ...args] = this.config.serverUrl.split(' ');
                transport = new stdio_js_1.StdioClientTransport({
                    command,
                    args,
                });
                break;
            default:
                throw new Error(`HTTP transport is not yet supported for MCP clients`);
        }
        await this.client.connect(transport);
        this.connected = true;
    }
    async disconnect() {
        if (this.connected) {
            await this.client.close();
            this.connected = false;
        }
    }
    async listTools() {
        await this.ensureConnected();
        return await this.client.request({ method: 'tools/list' }, types_js_1.ListToolsResultSchema);
    }
    async callTool(name, args) {
        await this.ensureConnected();
        return await this.client.request({
            method: 'tools/call',
            params: {
                name,
                arguments: args,
            },
        }, types_js_1.CallToolResultSchema);
    }
    async listResources() {
        await this.ensureConnected();
        return await this.client.request({ method: 'resources/list' }, types_js_1.ListResourcesResultSchema);
    }
    async readResource(uri) {
        await this.ensureConnected();
        return await this.client.request({
            method: 'resources/read',
            params: {
                uri,
            },
        }, types_js_1.ReadResourceResultSchema);
    }
    async listPrompts() {
        await this.ensureConnected();
        return await this.client.request({ method: 'prompts/list' }, types_js_1.ListPromptsResultSchema);
    }
    async getPrompt(name, args) {
        await this.ensureConnected();
        return await this.client.request({
            method: 'prompts/get',
            params: {
                name,
                arguments: args,
            },
        }, types_js_1.GetPromptResultSchema);
    }
    async ensureConnected() {
        if (!this.connected) {
            await this.connect();
        }
    }
}
exports.MCPClient = MCPClient;
//# sourceMappingURL=mcp-client.js.map