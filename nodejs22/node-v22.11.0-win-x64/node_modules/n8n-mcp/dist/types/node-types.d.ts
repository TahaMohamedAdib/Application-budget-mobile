import type { IVersionedNodeType, INodeType, INodeTypeBaseDescription, INodeTypeDescription } from 'n8n-workflow';
export type NodeClass = (new () => INodeType) | (new () => IVersionedNodeType) | INodeType | IVersionedNodeType;
export interface VersionedNodeInstance extends IVersionedNodeType {
    currentVersion: number;
    description: INodeTypeBaseDescription;
    nodeVersions: {
        [version: number]: INodeType;
    };
}
export interface RegularNodeInstance extends INodeType {
    description: INodeTypeDescription;
}
export type NodeInstance = VersionedNodeInstance | RegularNodeInstance;
export declare function isVersionedNodeInstance(node: any): node is VersionedNodeInstance;
export declare function isVersionedNodeClass(nodeClass: any): boolean;
export declare function instantiateNode(nodeClass: NodeClass): NodeInstance | null;
export declare function getNodeInstance(nodeClass: NodeClass): NodeInstance | undefined;
export declare function getNodeDescription(nodeClass: NodeClass): INodeTypeBaseDescription | INodeTypeDescription;
//# sourceMappingURL=node-types.d.ts.map