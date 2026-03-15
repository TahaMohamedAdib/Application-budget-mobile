import type { NodePropertyTypes } from 'n8n-workflow';
import type { TypeStructure } from '../types/type-structures';
export declare const TYPE_STRUCTURES: Record<NodePropertyTypes, TypeStructure>;
export declare const COMPLEX_TYPE_EXAMPLES: {
    collection: {
        basic: {
            name: string;
            email: string;
        };
        nested: {
            user: {
                firstName: string;
                lastName: string;
            };
            preferences: {
                theme: string;
                notifications: boolean;
            };
        };
        withExpressions: {
            id: string;
            timestamp: string;
            data: string;
        };
    };
    fixedCollection: {
        httpHeaders: {
            headers: {
                name: string;
                value: string;
            }[];
        };
        queryParameters: {
            queryParameters: {
                name: string;
                value: string;
            }[];
        };
        multipleCollections: {
            headers: {
                name: string;
                value: string;
            }[];
            queryParameters: {
                name: string;
                value: string;
            }[];
        };
    };
    filter: {
        simple: {
            conditions: {
                id: string;
                leftValue: string;
                operator: {
                    type: string;
                    operation: string;
                };
                rightValue: string;
            }[];
            combinator: string;
        };
        complex: {
            conditions: ({
                id: string;
                leftValue: string;
                operator: {
                    type: string;
                    operation: string;
                };
                rightValue: number;
            } | {
                id: string;
                leftValue: string;
                operator: {
                    type: string;
                    operation: string;
                };
                rightValue: string;
            })[];
            combinator: string;
        };
    };
    resourceMapper: {
        autoMap: {
            mappingMode: string;
            value: {};
        };
        manual: {
            mappingMode: string;
            value: {
                firstName: string;
                lastName: string;
                email: string;
                status: string;
            };
        };
    };
    assignmentCollection: {
        basic: {
            assignments: {
                id: string;
                name: string;
                value: string;
                type: string;
            }[];
        };
        multiple: {
            assignments: ({
                id: string;
                name: string;
                value: string;
                type: string;
            } | {
                id: string;
                name: string;
                value: boolean;
                type: string;
            })[];
        };
    };
};
//# sourceMappingURL=type-structures.d.ts.map