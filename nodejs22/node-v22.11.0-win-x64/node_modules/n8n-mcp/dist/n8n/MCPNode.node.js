"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MCPNode = void 0;
const n8n_workflow_1 = require("n8n-workflow");
const mcp_client_1 = require("../utils/mcp-client");
const bridge_1 = require("../utils/bridge");
class MCPNode {
    constructor() {
        this.description = {
            displayName: 'MCP',
            name: 'mcp',
            icon: 'file:mcp.svg',
            group: ['transform'],
            version: 1,
            description: 'Interact with Model Context Protocol (MCP) servers',
            defaults: {
                name: 'MCP',
            },
            inputs: ['main'],
            outputs: ['main'],
            credentials: [
                {
                    name: 'mcpApi',
                    required: true,
                },
            ],
            properties: [
                {
                    displayName: 'Operation',
                    name: 'operation',
                    type: 'options',
                    noDataExpression: true,
                    options: [
                        {
                            name: 'Call Tool',
                            value: 'callTool',
                            description: 'Execute an MCP tool',
                        },
                        {
                            name: 'List Tools',
                            value: 'listTools',
                            description: 'List available MCP tools',
                        },
                        {
                            name: 'Read Resource',
                            value: 'readResource',
                            description: 'Read an MCP resource',
                        },
                        {
                            name: 'List Resources',
                            value: 'listResources',
                            description: 'List available MCP resources',
                        },
                        {
                            name: 'Get Prompt',
                            value: 'getPrompt',
                            description: 'Get an MCP prompt',
                        },
                        {
                            name: 'List Prompts',
                            value: 'listPrompts',
                            description: 'List available MCP prompts',
                        },
                    ],
                    default: 'callTool',
                },
                {
                    displayName: 'Tool Name',
                    name: 'toolName',
                    type: 'string',
                    required: true,
                    displayOptions: {
                        show: {
                            operation: ['callTool'],
                        },
                    },
                    default: '',
                    description: 'Name of the MCP tool to execute',
                },
                {
                    displayName: 'Tool Arguments',
                    name: 'toolArguments',
                    type: 'json',
                    required: false,
                    displayOptions: {
                        show: {
                            operation: ['callTool'],
                        },
                    },
                    default: '{}',
                    description: 'Arguments to pass to the MCP tool',
                },
                {
                    displayName: 'Resource URI',
                    name: 'resourceUri',
                    type: 'string',
                    required: true,
                    displayOptions: {
                        show: {
                            operation: ['readResource'],
                        },
                    },
                    default: '',
                    description: 'URI of the MCP resource to read',
                },
                {
                    displayName: 'Prompt Name',
                    name: 'promptName',
                    type: 'string',
                    required: true,
                    displayOptions: {
                        show: {
                            operation: ['getPrompt'],
                        },
                    },
                    default: '',
                    description: 'Name of the MCP prompt to retrieve',
                },
                {
                    displayName: 'Prompt Arguments',
                    name: 'promptArguments',
                    type: 'json',
                    required: false,
                    displayOptions: {
                        show: {
                            operation: ['getPrompt'],
                        },
                    },
                    default: '{}',
                    description: 'Arguments to pass to the MCP prompt',
                },
            ],
        };
    }
    async execute() {
        const items = this.getInputData();
        const returnData = [];
        const operation = this.getNodeParameter('operation', 0);
        const credentials = await this.getCredentials('mcpApi');
        for (let itemIndex = 0; itemIndex < items.length; itemIndex++) {
            try {
                let result;
                switch (operation) {
                    case 'callTool':
                        const toolName = this.getNodeParameter('toolName', itemIndex);
                        const toolArgumentsJson = this.getNodeParameter('toolArguments', itemIndex);
                        const toolArguments = JSON.parse(toolArgumentsJson);
                        result = await this.callMCPTool(credentials, toolName, toolArguments);
                        break;
                    case 'listTools':
                        result = await this.listMCPTools(credentials);
                        break;
                    case 'readResource':
                        const resourceUri = this.getNodeParameter('resourceUri', itemIndex);
                        result = await this.readMCPResource(credentials, resourceUri);
                        break;
                    case 'listResources':
                        result = await this.listMCPResources(credentials);
                        break;
                    case 'getPrompt':
                        const promptName = this.getNodeParameter('promptName', itemIndex);
                        const promptArgumentsJson = this.getNodeParameter('promptArguments', itemIndex);
                        const promptArguments = JSON.parse(promptArgumentsJson);
                        result = await this.getMCPPrompt(credentials, promptName, promptArguments);
                        break;
                    case 'listPrompts':
                        result = await this.listMCPPrompts(credentials);
                        break;
                    default:
                        throw new n8n_workflow_1.NodeOperationError(this.getNode(), `Unknown operation: ${operation}`);
                }
                returnData.push({
                    json: result,
                    pairedItem: itemIndex,
                });
            }
            catch (error) {
                if (this.continueOnFail()) {
                    returnData.push({
                        json: {
                            error: error instanceof Error ? error.message : 'Unknown error',
                        },
                        pairedItem: itemIndex,
                    });
                    continue;
                }
                throw error;
            }
        }
        return [returnData];
    }
    async getMCPClient(credentials) {
        const client = new mcp_client_1.MCPClient({
            serverUrl: credentials.serverUrl,
            authToken: credentials.authToken,
            connectionType: credentials.connectionType || 'websocket',
        });
        await client.connect();
        return client;
    }
    async callMCPTool(credentials, toolName, args) {
        const client = await this.getMCPClient(credentials);
        try {
            const result = await client.callTool(toolName, args);
            return bridge_1.N8NMCPBridge.mcpToN8NExecutionData(result).json;
        }
        finally {
            await client.disconnect();
        }
    }
    async listMCPTools(credentials) {
        const client = await this.getMCPClient(credentials);
        try {
            return await client.listTools();
        }
        finally {
            await client.disconnect();
        }
    }
    async readMCPResource(credentials, uri) {
        const client = await this.getMCPClient(credentials);
        try {
            const result = await client.readResource(uri);
            return bridge_1.N8NMCPBridge.mcpToN8NExecutionData(result).json;
        }
        finally {
            await client.disconnect();
        }
    }
    async listMCPResources(credentials) {
        const client = await this.getMCPClient(credentials);
        try {
            return await client.listResources();
        }
        finally {
            await client.disconnect();
        }
    }
    async getMCPPrompt(credentials, promptName, args) {
        const client = await this.getMCPClient(credentials);
        try {
            const result = await client.getPrompt(promptName, args);
            return bridge_1.N8NMCPBridge.mcpPromptArgsToN8N(result);
        }
        finally {
            await client.disconnect();
        }
    }
    async listMCPPrompts(credentials) {
        const client = await this.getMCPClient(credentials);
        try {
            return await client.listPrompts();
        }
        finally {
            await client.disconnect();
        }
    }
}
exports.MCPNode = MCPNode;
//# sourceMappingURL=MCPNode.node.js.map