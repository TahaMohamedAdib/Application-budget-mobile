"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.N8NMCPBridge = void 0;
class N8NMCPBridge {
    static n8nToMCPToolArgs(data) {
        if (data.json) {
            return data.json;
        }
        const { pairedItem, ...cleanData } = data;
        return cleanData;
    }
    static mcpToN8NExecutionData(mcpResponse, itemIndex = 0) {
        if (mcpResponse.content && Array.isArray(mcpResponse.content)) {
            const textContent = mcpResponse.content
                .filter((c) => c.type === 'text')
                .map((c) => c.text)
                .join('\n');
            try {
                const parsed = JSON.parse(textContent);
                return {
                    json: parsed,
                    pairedItem: itemIndex,
                };
            }
            catch {
                return {
                    json: { result: textContent },
                    pairedItem: itemIndex,
                };
            }
        }
        return {
            json: mcpResponse,
            pairedItem: itemIndex,
        };
    }
    static n8nWorkflowToMCP(workflow) {
        return {
            id: workflow.id,
            name: workflow.name,
            description: workflow.description || '',
            nodes: workflow.nodes?.map((node) => ({
                id: node.id,
                type: node.type,
                name: node.name,
                parameters: node.parameters,
                position: node.position,
            })),
            connections: workflow.connections,
            settings: workflow.settings,
            metadata: {
                createdAt: workflow.createdAt,
                updatedAt: workflow.updatedAt,
                active: workflow.active,
            },
        };
    }
    static mcpToN8NWorkflow(mcpWorkflow) {
        return {
            name: mcpWorkflow.name,
            nodes: mcpWorkflow.nodes || [],
            connections: mcpWorkflow.connections || {},
            settings: mcpWorkflow.settings || {
                executionOrder: 'v1',
            },
            staticData: null,
            pinData: {},
        };
    }
    static n8nExecutionToMCPResource(execution) {
        return {
            uri: `execution://${execution.id}`,
            name: `Execution ${execution.id}`,
            description: `Workflow: ${execution.workflowData?.name || 'Unknown'}`,
            mimeType: 'application/json',
            data: {
                id: execution.id,
                workflowId: execution.workflowId,
                status: execution.finished ? 'completed' : execution.stoppedAt ? 'stopped' : 'running',
                mode: execution.mode,
                startedAt: execution.startedAt,
                stoppedAt: execution.stoppedAt,
                error: execution.data?.resultData?.error,
                executionData: execution.data,
            },
        };
    }
    static mcpPromptArgsToN8N(promptArgs) {
        return {
            prompt: promptArgs.name || '',
            arguments: promptArgs.arguments || {},
            messages: promptArgs.messages || [],
        };
    }
    static sanitizeData(data) {
        if (data === null || data === undefined) {
            return {};
        }
        if (typeof data !== 'object') {
            return { value: data };
        }
        const seen = new WeakSet();
        return JSON.parse(JSON.stringify(data, (_key, value) => {
            if (typeof value === 'object' && value !== null) {
                if (seen.has(value)) {
                    return '[Circular]';
                }
                seen.add(value);
            }
            return value;
        }));
    }
    static formatError(error) {
        return {
            message: error.message || 'Unknown error',
            type: error.name || 'Error',
            stack: error.stack,
            details: {
                code: error.code,
                statusCode: error.statusCode,
                data: error.data,
            },
        };
    }
}
exports.N8NMCPBridge = N8NMCPBridge;
//# sourceMappingURL=bridge.js.map