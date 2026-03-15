import { IExecuteFunctions, INodeExecutionData, INodeType, INodeTypeDescription } from 'n8n-workflow';
export declare class MCPNode implements INodeType {
    description: INodeTypeDescription;
    execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]>;
    private getMCPClient;
    private callMCPTool;
    private listMCPTools;
    private readMCPResource;
    private listMCPResources;
    private getMCPPrompt;
    private listMCPPrompts;
}
//# sourceMappingURL=MCPNode.node.d.ts.map