"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isComplexType = isComplexType;
exports.isPrimitiveType = isPrimitiveType;
exports.isTypeStructure = isTypeStructure;
function isComplexType(type) {
    return (type === 'collection' ||
        type === 'fixedCollection' ||
        type === 'resourceLocator' ||
        type === 'resourceMapper' ||
        type === 'filter' ||
        type === 'assignmentCollection');
}
function isPrimitiveType(type) {
    return (type === 'string' ||
        type === 'number' ||
        type === 'boolean' ||
        type === 'dateTime' ||
        type === 'color' ||
        type === 'json');
}
function isTypeStructure(value) {
    return (value !== null &&
        typeof value === 'object' &&
        'type' in value &&
        'jsType' in value &&
        'description' in value &&
        'example' in value &&
        ['primitive', 'object', 'array', 'collection', 'special'].includes(value.type) &&
        ['string', 'number', 'boolean', 'object', 'array', 'any'].includes(value.jsType));
}
//# sourceMappingURL=type-structures.js.map