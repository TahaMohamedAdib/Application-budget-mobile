"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.n8nFriendlyDescriptions = void 0;
exports.makeToolsN8nFriendly = makeToolsN8nFriendly;
exports.n8nFriendlyDescriptions = {
    validate_node: {
        description: 'Validate n8n node config. Pass nodeType (string) and config (object). Use mode="full" for comprehensive validation, mode="minimal" for quick check. Example: {"nodeType": "nodes-base.slack", "config": {"resource": "channel", "operation": "create"}}',
        params: {
            nodeType: 'String value like "nodes-base.slack"',
            config: 'Object value like {"resource": "channel", "operation": "create"} or empty object {}',
            mode: 'Optional string: "full" (default) or "minimal"',
            profile: 'Optional string: "minimal" or "runtime" or "ai-friendly" or "strict"'
        }
    },
    search_nodes: {
        description: 'Search nodes. Pass query (string). Example: {"query": "webhook"}',
        params: {
            query: 'String keyword like "webhook" or "database"',
            limit: 'Optional number, default 20'
        }
    },
    get_node: {
        description: 'Get node info with multiple modes. Pass nodeType (string). Use mode="info" for config, mode="docs" for documentation, mode="search_properties" with propertyQuery for finding fields. Example: {"nodeType": "nodes-base.httpRequest", "detail": "standard"}',
        params: {
            nodeType: 'String with prefix like "nodes-base.httpRequest"',
            mode: 'Optional string: "info" (default), "docs", "search_properties", "versions", "compare", "breaking", "migrations"',
            detail: 'Optional string: "minimal", "standard" (default), "full"',
            propertyQuery: 'For mode="search_properties": search term like "auth"'
        }
    },
    validate_workflow: {
        description: 'Validate workflow structure, connections, and expressions. Pass workflow object. MUST have: {"workflow": {"nodes": [array of node objects], "connections": {object with node connections}}}. Each node needs: name, type, typeVersion, position.',
        params: {
            workflow: 'Object with two required fields: nodes (array) and connections (object). Example: {"nodes": [{"name": "Webhook", "type": "n8n-nodes-base.webhook", "typeVersion": 2, "position": [250, 300], "parameters": {}}], "connections": {}}',
            options: 'Optional object. Example: {"validateNodes": true, "validateConnections": true, "validateExpressions": true, "profile": "runtime"}'
        }
    },
    search_templates: {
        description: 'Search workflow templates with multiple modes. Use searchMode="keyword" for text search, searchMode="by_nodes" to find by node types, searchMode="by_task" for task-based templates, searchMode="by_metadata" for filtering. Example: {"query": "chatbot"} or {"searchMode": "by_task", "task": "webhook_processing"}',
        params: {
            query: 'For searchMode="keyword": string keyword like "chatbot"',
            searchMode: 'Optional: "keyword" (default), "by_nodes", "by_task", "by_metadata"',
            nodeTypes: 'For searchMode="by_nodes": array like ["n8n-nodes-base.httpRequest"]',
            task: 'For searchMode="by_task": task like "webhook_processing", "ai_automation"',
            limit: 'Optional number, default 20'
        }
    },
    get_template: {
        description: 'Get template by ID. Pass templateId (number). Example: {"templateId": 1234}',
        params: {
            templateId: 'Number ID like 1234',
            mode: 'Optional: "full" (default), "nodes_only", "structure"'
        }
    },
    tools_documentation: {
        description: 'Get tool docs. Pass optional depth (string). Example: {"depth": "essentials"} or {}',
        params: {
            depth: 'Optional string: "essentials" (default) or "full"',
            topic: 'Optional string tool name like "search_nodes"'
        }
    }
};
function makeToolsN8nFriendly(tools) {
    return tools.map(tool => {
        const toolName = tool.name;
        const friendlyDesc = exports.n8nFriendlyDescriptions[toolName];
        if (friendlyDesc) {
            const updatedTool = { ...tool };
            updatedTool.description = friendlyDesc.description;
            if (tool.inputSchema?.properties) {
                updatedTool.inputSchema = {
                    ...tool.inputSchema,
                    properties: { ...tool.inputSchema.properties }
                };
                Object.keys(updatedTool.inputSchema.properties).forEach(param => {
                    if (friendlyDesc.params[param]) {
                        updatedTool.inputSchema.properties[param] = {
                            ...updatedTool.inputSchema.properties[param],
                            description: friendlyDesc.params[param]
                        };
                    }
                });
            }
            return updatedTool;
        }
        return tool;
    });
}
//# sourceMappingURL=tools-n8n-friendly.js.map