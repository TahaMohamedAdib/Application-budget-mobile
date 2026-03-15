import type { NodePropertyTypes } from 'n8n-workflow';
export interface TypeStructure {
    type: 'primitive' | 'object' | 'array' | 'collection' | 'special';
    jsType: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'any';
    description: string;
    structure?: {
        properties?: Record<string, TypePropertyDefinition>;
        items?: TypePropertyDefinition;
        flexible?: boolean;
        required?: string[];
    };
    example: any;
    examples?: any[];
    validation?: {
        allowEmpty?: boolean;
        allowExpressions?: boolean;
        min?: number;
        max?: number;
        pattern?: string;
        customValidator?: string;
    };
    introducedIn?: string;
    deprecatedIn?: string;
    replacedBy?: NodePropertyTypes;
    notes?: string[];
}
export interface TypePropertyDefinition {
    type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'any';
    description?: string;
    required?: boolean;
    properties?: Record<string, TypePropertyDefinition>;
    items?: TypePropertyDefinition;
    example?: any;
    enum?: Array<string | number | boolean>;
    flexible?: boolean;
}
export type ComplexPropertyType = 'collection' | 'fixedCollection' | 'resourceLocator' | 'resourceMapper' | 'filter' | 'assignmentCollection';
export type PrimitivePropertyType = 'string' | 'number' | 'boolean' | 'dateTime' | 'color' | 'json';
export declare function isComplexType(type: NodePropertyTypes): type is ComplexPropertyType;
export declare function isPrimitiveType(type: NodePropertyTypes): type is PrimitivePropertyType;
export declare function isTypeStructure(value: any): value is TypeStructure;
//# sourceMappingURL=type-structures.d.ts.map