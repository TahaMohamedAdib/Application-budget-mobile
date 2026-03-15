"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isStickyNote = isStickyNote;
exports.isTriggerNode = isTriggerNode;
exports.isNonExecutableNode = isNonExecutableNode;
exports.requiresIncomingConnection = requiresIncomingConnection;
const node_type_utils_1 = require("./node-type-utils");
function isStickyNote(nodeType) {
    const stickyNoteTypes = [
        'n8n-nodes-base.stickyNote',
        'nodes-base.stickyNote',
        '@n8n/n8n-nodes-base.stickyNote'
    ];
    return stickyNoteTypes.includes(nodeType);
}
function isTriggerNode(nodeType) {
    return (0, node_type_utils_1.isTriggerNode)(nodeType);
}
function isNonExecutableNode(nodeType) {
    return isStickyNote(nodeType);
}
function requiresIncomingConnection(nodeType) {
    if (isNonExecutableNode(nodeType)) {
        return false;
    }
    if (isTriggerNode(nodeType)) {
        return false;
    }
    return true;
}
//# sourceMappingURL=node-classification.js.map