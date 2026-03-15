import type { NodePropertyTypes } from 'n8n-workflow';
import type { TypeStructure } from '../types/type-structures';
export interface TypeValidationResult {
    valid: boolean;
    errors: string[];
    warnings: string[];
}
export declare class TypeStructureService {
    static getStructure(type: NodePropertyTypes): TypeStructure | null;
    static getAllStructures(): Record<NodePropertyTypes, TypeStructure>;
    static getExample(type: NodePropertyTypes): any;
    static getExamples(type: NodePropertyTypes): any[];
    static isComplexType(type: NodePropertyTypes): boolean;
    static isPrimitiveType(type: NodePropertyTypes): boolean;
    static getComplexTypes(): NodePropertyTypes[];
    static getPrimitiveTypes(): NodePropertyTypes[];
    static getComplexExamples(type: 'collection' | 'fixedCollection' | 'filter' | 'resourceMapper' | 'assignmentCollection'): Record<string, any> | null;
    static validateTypeCompatibility(value: any, type: NodePropertyTypes): TypeValidationResult;
    static getDescription(type: NodePropertyTypes): string | null;
    static getNotes(type: NodePropertyTypes): string[];
    static getJavaScriptType(type: NodePropertyTypes): 'string' | 'number' | 'boolean' | 'object' | 'array' | 'any' | null;
}
//# sourceMappingURL=type-structure-service.d.ts.map