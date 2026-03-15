"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SimpleParser = void 0;
const node_types_1 = require("../types/node-types");
class SimpleParser {
    parse(nodeClass) {
        let description;
        let isVersioned = false;
        try {
            if ((0, node_types_1.isVersionedNodeClass)(nodeClass)) {
                const instance = new nodeClass();
                const inst = instance;
                description = inst.description || (inst.nodeVersions ? inst.baseDescription : undefined);
                if (!description) {
                    description = {};
                }
                isVersioned = true;
                if (inst.nodeVersions && inst.currentVersion) {
                    const currentVersionNode = inst.nodeVersions[inst.currentVersion];
                    if (currentVersionNode && currentVersionNode.description) {
                        description = { ...description, ...currentVersionNode.description };
                    }
                }
            }
            else if (typeof nodeClass === 'function') {
                try {
                    const instance = new nodeClass();
                    description = instance.description;
                    if (!description || !description.name) {
                        const inst = instance;
                        if (inst.baseDescription?.name) {
                            description = inst.baseDescription;
                        }
                    }
                }
                catch (e) {
                    description = {};
                }
            }
            else {
                description = nodeClass.description;
                if (!description || !description.name) {
                    const inst = nodeClass;
                    if (inst.baseDescription?.name) {
                        description = inst.baseDescription;
                    }
                }
            }
        }
        catch (error) {
            description = nodeClass.description || {};
        }
        const desc = description;
        const isDeclarative = !!desc.routing;
        if (!description.name) {
            throw new Error('Node is missing name property');
        }
        return {
            style: isDeclarative ? 'declarative' : 'programmatic',
            nodeType: description.name,
            displayName: description.displayName || description.name,
            description: description.description,
            category: description.group?.[0] || desc.categories?.[0],
            properties: desc.properties || [],
            credentials: desc.credentials || [],
            isAITool: desc.usableAsTool === true,
            isTrigger: this.detectTrigger(description),
            isWebhook: desc.webhooks?.length > 0,
            operations: isDeclarative ? this.extractOperations(desc.routing) : this.extractProgrammaticOperations(desc),
            version: this.extractVersion(nodeClass),
            isVersioned: isVersioned || this.isVersionedNode(nodeClass) || Array.isArray(desc.version) || desc.defaultVersion !== undefined
        };
    }
    detectTrigger(description) {
        if (description.group && Array.isArray(description.group)) {
            if (description.group.includes('trigger')) {
                return true;
            }
        }
        const desc = description;
        return desc.polling === true ||
            desc.trigger === true ||
            desc.eventTrigger === true ||
            description.name?.toLowerCase().includes('trigger');
    }
    extractOperations(routing) {
        const operations = [];
        if (routing?.request) {
            const resources = routing.request.resource?.options || [];
            resources.forEach((resource) => {
                operations.push({
                    resource: resource.value,
                    name: resource.name
                });
            });
            const operationOptions = routing.request.operation?.options || [];
            operationOptions.forEach((operation) => {
                operations.push({
                    operation: operation.value,
                    name: operation.name || operation.displayName
                });
            });
        }
        if (routing?.operations) {
            Object.entries(routing.operations).forEach(([key, value]) => {
                operations.push({
                    operation: key,
                    name: value.displayName || key
                });
            });
        }
        return operations;
    }
    extractProgrammaticOperations(description) {
        const operations = [];
        if (!description.properties || !Array.isArray(description.properties)) {
            return operations;
        }
        const resourceProp = description.properties.find((p) => p.name === 'resource' && p.type === 'options');
        if (resourceProp && resourceProp.options) {
            resourceProp.options.forEach((resource) => {
                operations.push({
                    type: 'resource',
                    resource: resource.value,
                    name: resource.name
                });
            });
        }
        const operationProps = description.properties.filter((p) => p.name === 'operation' && p.type === 'options' && p.displayOptions);
        operationProps.forEach((opProp) => {
            if (opProp.options) {
                opProp.options.forEach((operation) => {
                    const resourceCondition = opProp.displayOptions?.show?.resource;
                    const resources = Array.isArray(resourceCondition) ? resourceCondition : [resourceCondition];
                    operations.push({
                        type: 'operation',
                        operation: operation.value,
                        name: operation.name,
                        action: operation.action,
                        resources: resources
                    });
                });
            }
        });
        return operations;
    }
    extractVersion(nodeClass) {
        try {
            const instance = typeof nodeClass === 'function' ? new nodeClass() : nodeClass;
            const inst = instance;
            if (inst?.currentVersion !== undefined) {
                return inst.currentVersion.toString();
            }
            if (inst?.description?.defaultVersion) {
                return inst.description.defaultVersion.toString();
            }
            if (inst?.nodeVersions) {
                const versions = Object.keys(inst.nodeVersions).map(Number);
                if (versions.length > 0) {
                    const maxVersion = Math.max(...versions);
                    if (!isNaN(maxVersion)) {
                        return maxVersion.toString();
                    }
                }
            }
            if (inst?.description?.version) {
                return inst.description.version.toString();
            }
        }
        catch (e) {
        }
        const nodeClassAny = nodeClass;
        if (nodeClassAny.description?.defaultVersion) {
            return nodeClassAny.description.defaultVersion.toString();
        }
        if (nodeClassAny.nodeVersions) {
            const versions = Object.keys(nodeClassAny.nodeVersions).map(Number);
            if (versions.length > 0) {
                const maxVersion = Math.max(...versions);
                if (!isNaN(maxVersion)) {
                    return maxVersion.toString();
                }
            }
        }
        return nodeClassAny.description?.version || '1';
    }
    isVersionedNode(nodeClass) {
        const nodeClassAny = nodeClass;
        if (nodeClassAny.baseDescription && nodeClassAny.nodeVersions) {
            return true;
        }
        try {
            const instance = typeof nodeClass === 'function' ? new nodeClass() : nodeClass;
            const inst = instance;
            if (inst.baseDescription && inst.nodeVersions) {
                return true;
            }
            const description = inst.description || {};
            if (Array.isArray(description.version)) {
                return true;
            }
            if (description.defaultVersion !== undefined) {
                return true;
            }
        }
        catch (e) {
        }
        return false;
    }
}
exports.SimpleParser = SimpleParser;
//# sourceMappingURL=simple-parser.js.map