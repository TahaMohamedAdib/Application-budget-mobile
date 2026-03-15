"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TypeStructureService = void 0;
const type_structures_1 = require("../types/type-structures");
const type_structures_2 = require("../constants/type-structures");
class TypeStructureService {
    static getStructure(type) {
        return type_structures_2.TYPE_STRUCTURES[type] || null;
    }
    static getAllStructures() {
        return { ...type_structures_2.TYPE_STRUCTURES };
    }
    static getExample(type) {
        const structure = this.getStructure(type);
        return structure ? structure.example : null;
    }
    static getExamples(type) {
        const structure = this.getStructure(type);
        if (!structure)
            return [];
        return structure.examples || [structure.example];
    }
    static isComplexType(type) {
        return (0, type_structures_1.isComplexType)(type);
    }
    static isPrimitiveType(type) {
        return (0, type_structures_1.isPrimitiveType)(type);
    }
    static getComplexTypes() {
        return Object.entries(type_structures_2.TYPE_STRUCTURES)
            .filter(([, structure]) => structure.type === 'collection' || structure.type === 'special')
            .filter(([type]) => this.isComplexType(type))
            .map(([type]) => type);
    }
    static getPrimitiveTypes() {
        return Object.keys(type_structures_2.TYPE_STRUCTURES).filter((type) => this.isPrimitiveType(type));
    }
    static getComplexExamples(type) {
        return type_structures_2.COMPLEX_TYPE_EXAMPLES[type] || null;
    }
    static validateTypeCompatibility(value, type) {
        const structure = this.getStructure(type);
        if (!structure) {
            return {
                valid: false,
                errors: [`Unknown property type: ${type}`],
                warnings: [],
            };
        }
        const errors = [];
        const warnings = [];
        if (value === null || value === undefined) {
            if (!structure.validation?.allowEmpty) {
                errors.push(`Value is required for type ${type}`);
            }
            return { valid: errors.length === 0, errors, warnings };
        }
        const actualType = Array.isArray(value) ? 'array' : typeof value;
        const expectedType = structure.jsType;
        if (expectedType !== 'any' && actualType !== expectedType) {
            const isExpression = typeof value === 'string' && value.includes('{{');
            if (isExpression && structure.validation?.allowExpressions) {
                warnings.push(`Value contains n8n expression - cannot validate type until runtime`);
            }
            else {
                errors.push(`Expected ${expectedType} but got ${actualType}`);
            }
        }
        if (type === 'dateTime' && typeof value === 'string') {
            const pattern = structure.validation?.pattern;
            if (pattern && !new RegExp(pattern).test(value)) {
                errors.push(`Invalid dateTime format. Expected ISO 8601 format.`);
            }
        }
        if (type === 'color' && typeof value === 'string') {
            const pattern = structure.validation?.pattern;
            if (pattern && !new RegExp(pattern).test(value)) {
                errors.push(`Invalid color format. Expected 6-digit hex color (e.g., #FF5733).`);
            }
        }
        if (type === 'json' && typeof value === 'string') {
            try {
                JSON.parse(value);
            }
            catch {
                errors.push(`Invalid JSON string. Must be valid JSON when parsed.`);
            }
        }
        return {
            valid: errors.length === 0,
            errors,
            warnings,
        };
    }
    static getDescription(type) {
        const structure = this.getStructure(type);
        return structure ? structure.description : null;
    }
    static getNotes(type) {
        const structure = this.getStructure(type);
        return structure?.notes || [];
    }
    static getJavaScriptType(type) {
        const structure = this.getStructure(type);
        return structure ? structure.jsType : null;
    }
}
exports.TypeStructureService = TypeStructureService;
//# sourceMappingURL=type-structure-service.js.map