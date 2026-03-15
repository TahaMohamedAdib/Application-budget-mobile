import { INodeExecutionData, IDataObject } from 'n8n-workflow';
export declare class N8NMCPBridge {
    static n8nToMCPToolArgs(data: IDataObject): any;
    static mcpToN8NExecutionData(mcpResponse: any, itemIndex?: number): INodeExecutionData;
    static n8nWorkflowToMCP(workflow: any): any;
    static mcpToN8NWorkflow(mcpWorkflow: any): any;
    static n8nExecutionToMCPResource(execution: any): any;
    static mcpPromptArgsToN8N(promptArgs: any): IDataObject;
    static sanitizeData(data: any): any;
    static formatError(error: any): any;
}
//# sourceMappingURL=bridge.d.ts.map