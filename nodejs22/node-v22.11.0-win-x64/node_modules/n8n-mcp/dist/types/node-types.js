"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isVersionedNodeInstance = isVersionedNodeInstance;
exports.isVersionedNodeClass = isVersionedNodeClass;
exports.instantiateNode = instantiateNode;
exports.getNodeInstance = getNodeInstance;
exports.getNodeDescription = getNodeDescription;
function isVersionedNodeInstance(node) {
    return (node !== null &&
        typeof node === 'object' &&
        'nodeVersions' in node &&
        'currentVersion' in node &&
        'description' in node &&
        typeof node.currentVersion === 'number');
}
function isVersionedNodeClass(nodeClass) {
    return (typeof nodeClass === 'function' &&
        nodeClass.prototype?.constructor?.name === 'VersionedNodeType');
}
function instantiateNode(nodeClass) {
    try {
        if (typeof nodeClass === 'function') {
            return new nodeClass();
        }
        return nodeClass;
    }
    catch (e) {
        return null;
    }
}
function getNodeInstance(nodeClass) {
    const instance = instantiateNode(nodeClass);
    return instance ?? undefined;
}
function getNodeDescription(nodeClass) {
    try {
        const instance = instantiateNode(nodeClass);
        if (instance) {
            if (isVersionedNodeInstance(instance)) {
                return instance.description;
            }
            return instance.description;
        }
    }
    catch (e) {
    }
    if (typeof nodeClass === 'object' && 'description' in nodeClass) {
        return nodeClass.description;
    }
    return {
        displayName: '',
        name: '',
        group: [],
        description: '',
        version: 1,
        defaults: { name: '', color: '' },
        inputs: [],
        outputs: [],
        properties: []
    };
}
//# sourceMappingURL=node-types.js.map