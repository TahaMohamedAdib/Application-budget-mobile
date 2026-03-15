"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalizeNodeType = normalizeNodeType;
exports.getNodeTypeAlternatives = getNodeTypeAlternatives;
exports.getWorkflowNodeType = getWorkflowNodeType;
function normalizeNodeType(nodeType) {
    if (nodeType.startsWith('n8n-nodes-base.')) {
        return nodeType.replace('n8n-nodes-base.', 'nodes-base.');
    }
    if (nodeType.startsWith('@n8n/n8n-nodes-langchain.')) {
        return nodeType.replace('@n8n/n8n-nodes-langchain.', 'nodes-langchain.');
    }
    if (nodeType.startsWith('n8n-nodes-langchain.')) {
        return nodeType.replace('n8n-nodes-langchain.', 'nodes-langchain.');
    }
    return nodeType;
}
function getNodeTypeAlternatives(nodeType) {
    if (!nodeType || typeof nodeType !== 'string' || nodeType.trim() === '') {
        return [];
    }
    const alternatives = [];
    alternatives.push(nodeType.toLowerCase());
    if (nodeType.includes('.')) {
        const [prefix, nodeName] = nodeType.split('.');
        if (nodeName && nodeName.toLowerCase() !== nodeName) {
            alternatives.push(`${prefix}.${nodeName.toLowerCase()}`);
        }
        if (nodeName && nodeName.toLowerCase() === nodeName && nodeName.length > 1) {
            const camelCaseVariants = generateCamelCaseVariants(nodeName);
            camelCaseVariants.forEach(variant => {
                alternatives.push(`${prefix}.${variant}`);
            });
        }
    }
    if (!nodeType.includes('.')) {
        alternatives.push(`nodes-base.${nodeType}`);
        alternatives.push(`nodes-langchain.${nodeType}`);
        const camelCaseVariants = generateCamelCaseVariants(nodeType);
        camelCaseVariants.forEach(variant => {
            alternatives.push(`nodes-base.${variant}`);
            alternatives.push(`nodes-langchain.${variant}`);
        });
    }
    const normalizedAlternatives = alternatives.map(alt => normalizeNodeType(alt));
    return [...new Set([...alternatives, ...normalizedAlternatives])];
}
function generateCamelCaseVariants(str) {
    const variants = [];
    const patterns = [
        /^(.+)(trigger|node|request|response)$/i,
        /^(http|mysql|postgres|mongo|redis|mqtt|smtp|imap|ftp|ssh|api)(.+)$/i,
        /^(google|microsoft|amazon|slack|discord|telegram)(.+)$/i,
    ];
    for (const pattern of patterns) {
        const match = str.toLowerCase().match(pattern);
        if (match) {
            const [, first, second] = match;
            variants.push(first.toLowerCase() + second.charAt(0).toUpperCase() + second.slice(1).toLowerCase());
        }
    }
    if (variants.length === 0) {
        const words = str.split(/[-_\s]+/);
        if (words.length > 1) {
            const camelCase = words[0].toLowerCase() + words.slice(1).map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()).join('');
            variants.push(camelCase);
        }
    }
    return variants;
}
function getWorkflowNodeType(packageName, nodeType) {
    const nodeName = nodeType.split('.').pop() || nodeType;
    if (packageName === 'n8n-nodes-base') {
        return `n8n-nodes-base.${nodeName}`;
    }
    else if (packageName === '@n8n/n8n-nodes-langchain') {
        return `@n8n/n8n-nodes-langchain.${nodeName}`;
    }
    return nodeType;
}
//# sourceMappingURL=node-utils.js.map