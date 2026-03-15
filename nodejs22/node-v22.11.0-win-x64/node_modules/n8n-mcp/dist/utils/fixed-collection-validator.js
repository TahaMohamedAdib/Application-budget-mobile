"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FixedCollectionValidator = void 0;
class FixedCollectionValidator {
    static isNodeConfig(value) {
        return typeof value === 'object' && value !== null && !Array.isArray(value);
    }
    static getNestedValue(obj, path) {
        const parts = path.split('.');
        let current = obj;
        for (const part of parts) {
            if (!this.isNodeConfig(current)) {
                return undefined;
            }
            current = current[part];
        }
        return current;
    }
    static validate(nodeType, config) {
        if (typeof config !== 'object' || config === null || Array.isArray(config)) {
            return { isValid: true, errors: [] };
        }
        const normalizedNodeType = this.normalizeNodeType(nodeType);
        const pattern = this.getPatternForNode(normalizedNodeType);
        if (!pattern) {
            return { isValid: true, errors: [] };
        }
        const result = {
            isValid: true,
            errors: []
        };
        for (const invalidPattern of pattern.invalidPatterns) {
            if (this.hasInvalidStructure(config, invalidPattern)) {
                result.isValid = false;
                result.errors.push({
                    pattern: invalidPattern,
                    message: `Invalid structure for nodes-base.${pattern.nodeType} node: found nested "${invalidPattern}" but expected "${pattern.expectedStructure}". This causes "propertyValues[itemName] is not iterable" error in n8n.`,
                    fix: this.generateFixMessage(pattern)
                });
                if (!result.autofix) {
                    result.autofix = this.generateAutofix(config, pattern);
                }
            }
        }
        return result;
    }
    static applyAutofix(config, pattern) {
        const fixedConfig = this.generateAutofix(config, pattern);
        if (pattern.nodeType === 'if' || pattern.nodeType === 'filter') {
            const conditions = config.conditions;
            if (conditions && typeof conditions === 'object' && !Array.isArray(conditions) && 'values' in conditions) {
                const values = conditions.values;
                if (values !== undefined && values !== null &&
                    (Array.isArray(values) || typeof values === 'object')) {
                    return values;
                }
            }
        }
        return fixedConfig;
    }
    static normalizeNodeType(nodeType) {
        return nodeType
            .replace('n8n-nodes-base.', '')
            .replace('nodes-base.', '')
            .replace('@n8n/n8n-nodes-langchain.', '')
            .toLowerCase();
    }
    static getPatternForNode(nodeType) {
        return this.KNOWN_PATTERNS.find(p => p.nodeType === nodeType);
    }
    static hasInvalidStructure(config, pattern) {
        const parts = pattern.split('.');
        let current = config;
        const visited = new WeakSet();
        for (const part of parts) {
            if (current === null || current === undefined) {
                return false;
            }
            if (typeof current !== 'object' || Array.isArray(current)) {
                return false;
            }
            if (visited.has(current)) {
                return false;
            }
            visited.add(current);
            if (!Object.prototype.hasOwnProperty.call(current, part)) {
                return false;
            }
            const nextValue = current[part];
            if (typeof nextValue !== 'object' || nextValue === null) {
                if (parts.indexOf(part) < parts.length - 1) {
                    return false;
                }
            }
            current = nextValue;
        }
        return true;
    }
    static generateFixMessage(pattern) {
        switch (pattern.nodeType) {
            case 'switch':
                return 'Use: { "rules": { "values": [{ "conditions": {...}, "outputKey": "output1" }] } }';
            case 'if':
            case 'filter':
                return 'Use: { "conditions": {...} } or { "conditions": [...] } directly, not nested under "values"';
            case 'summarize':
                return 'Use: { "fieldsToSummarize": { "values": [...] } } not nested values.values';
            case 'comparedatasets':
                return 'Use: { "mergeByFields": { "values": [...] } } not nested values.values';
            case 'sort':
                return 'Use: { "sortFieldsUi": { "sortField": [...] } } not sortField.values';
            case 'aggregate':
                return 'Use: { "fieldsToAggregate": { "fieldToAggregate": [...] } } not fieldToAggregate.values';
            case 'set':
                return 'Use: { "fields": { "values": [...] } } not nested values.values';
            case 'html':
                return 'Use: { "extractionValues": { "values": [...] } } not nested values.values';
            case 'httprequest':
                return 'Use: { "body": { "parameters": [...] } } not parameters.values';
            case 'airtable':
                return 'Use: { "sort": { "sortField": [...] } } not sortField.values';
            default:
                return `Use ${pattern.expectedStructure} structure`;
        }
    }
    static generateAutofix(config, pattern) {
        const fixedConfig = { ...config };
        switch (pattern.nodeType) {
            case 'switch': {
                const rules = config.rules;
                if (this.isNodeConfig(rules)) {
                    const conditions = rules.conditions;
                    if (this.isNodeConfig(conditions) && 'values' in conditions) {
                        const values = conditions.values;
                        fixedConfig.rules = {
                            values: Array.isArray(values)
                                ? values.map((condition, index) => ({
                                    conditions: condition,
                                    outputKey: `output${index + 1}`
                                }))
                                : [{
                                        conditions: values,
                                        outputKey: 'output1'
                                    }]
                        };
                    }
                    else if (conditions) {
                        fixedConfig.rules = {
                            values: [{
                                    conditions: conditions,
                                    outputKey: 'output1'
                                }]
                        };
                    }
                }
                break;
            }
            case 'if':
            case 'filter': {
                const conditions = config.conditions;
                if (this.isNodeConfig(conditions) && 'values' in conditions) {
                    const values = conditions.values;
                    if (values !== undefined && values !== null &&
                        (Array.isArray(values) || typeof values === 'object')) {
                        return values;
                    }
                }
                break;
            }
            case 'summarize': {
                const fieldsToSummarize = config.fieldsToSummarize;
                if (this.isNodeConfig(fieldsToSummarize)) {
                    const values = fieldsToSummarize.values;
                    if (this.isNodeConfig(values) && 'values' in values) {
                        fixedConfig.fieldsToSummarize = {
                            values: values.values
                        };
                    }
                }
                break;
            }
            case 'comparedatasets': {
                const mergeByFields = config.mergeByFields;
                if (this.isNodeConfig(mergeByFields)) {
                    const values = mergeByFields.values;
                    if (this.isNodeConfig(values) && 'values' in values) {
                        fixedConfig.mergeByFields = {
                            values: values.values
                        };
                    }
                }
                break;
            }
            case 'sort': {
                const sortFieldsUi = config.sortFieldsUi;
                if (this.isNodeConfig(sortFieldsUi)) {
                    const sortField = sortFieldsUi.sortField;
                    if (this.isNodeConfig(sortField) && 'values' in sortField) {
                        fixedConfig.sortFieldsUi = {
                            sortField: sortField.values
                        };
                    }
                }
                break;
            }
            case 'aggregate': {
                const fieldsToAggregate = config.fieldsToAggregate;
                if (this.isNodeConfig(fieldsToAggregate)) {
                    const fieldToAggregate = fieldsToAggregate.fieldToAggregate;
                    if (this.isNodeConfig(fieldToAggregate) && 'values' in fieldToAggregate) {
                        fixedConfig.fieldsToAggregate = {
                            fieldToAggregate: fieldToAggregate.values
                        };
                    }
                }
                break;
            }
            case 'set': {
                const fields = config.fields;
                if (this.isNodeConfig(fields)) {
                    const values = fields.values;
                    if (this.isNodeConfig(values) && 'values' in values) {
                        fixedConfig.fields = {
                            values: values.values
                        };
                    }
                }
                break;
            }
            case 'html': {
                const extractionValues = config.extractionValues;
                if (this.isNodeConfig(extractionValues)) {
                    const values = extractionValues.values;
                    if (this.isNodeConfig(values) && 'values' in values) {
                        fixedConfig.extractionValues = {
                            values: values.values
                        };
                    }
                }
                break;
            }
            case 'httprequest': {
                const body = config.body;
                if (this.isNodeConfig(body)) {
                    const parameters = body.parameters;
                    if (this.isNodeConfig(parameters) && 'values' in parameters) {
                        fixedConfig.body = {
                            ...body,
                            parameters: parameters.values
                        };
                    }
                }
                break;
            }
            case 'airtable': {
                const sort = config.sort;
                if (this.isNodeConfig(sort)) {
                    const sortField = sort.sortField;
                    if (this.isNodeConfig(sortField) && 'values' in sortField) {
                        fixedConfig.sort = {
                            sortField: sortField.values
                        };
                    }
                }
                break;
            }
        }
        return fixedConfig;
    }
    static getAllPatterns() {
        return this.KNOWN_PATTERNS.map(pattern => ({
            ...pattern,
            invalidPatterns: [...pattern.invalidPatterns]
        }));
    }
    static isNodeSusceptible(nodeType) {
        const normalizedType = this.normalizeNodeType(nodeType);
        return this.KNOWN_PATTERNS.some(p => p.nodeType === normalizedType);
    }
}
exports.FixedCollectionValidator = FixedCollectionValidator;
FixedCollectionValidator.KNOWN_PATTERNS = [
    {
        nodeType: 'switch',
        property: 'rules',
        expectedStructure: 'rules.values array',
        invalidPatterns: ['rules.conditions', 'rules.conditions.values']
    },
    {
        nodeType: 'if',
        property: 'conditions',
        expectedStructure: 'conditions array/object',
        invalidPatterns: ['conditions.values']
    },
    {
        nodeType: 'filter',
        property: 'conditions',
        expectedStructure: 'conditions array/object',
        invalidPatterns: ['conditions.values']
    },
    {
        nodeType: 'summarize',
        property: 'fieldsToSummarize',
        subProperty: 'values',
        expectedStructure: 'fieldsToSummarize.values array',
        invalidPatterns: ['fieldsToSummarize.values.values']
    },
    {
        nodeType: 'comparedatasets',
        property: 'mergeByFields',
        subProperty: 'values',
        expectedStructure: 'mergeByFields.values array',
        invalidPatterns: ['mergeByFields.values.values']
    },
    {
        nodeType: 'sort',
        property: 'sortFieldsUi',
        subProperty: 'sortField',
        expectedStructure: 'sortFieldsUi.sortField array',
        invalidPatterns: ['sortFieldsUi.sortField.values']
    },
    {
        nodeType: 'aggregate',
        property: 'fieldsToAggregate',
        subProperty: 'fieldToAggregate',
        expectedStructure: 'fieldsToAggregate.fieldToAggregate array',
        invalidPatterns: ['fieldsToAggregate.fieldToAggregate.values']
    },
    {
        nodeType: 'set',
        property: 'fields',
        subProperty: 'values',
        expectedStructure: 'fields.values array',
        invalidPatterns: ['fields.values.values']
    },
    {
        nodeType: 'html',
        property: 'extractionValues',
        subProperty: 'values',
        expectedStructure: 'extractionValues.values array',
        invalidPatterns: ['extractionValues.values.values']
    },
    {
        nodeType: 'httprequest',
        property: 'body',
        subProperty: 'parameters',
        expectedStructure: 'body.parameters array',
        invalidPatterns: ['body.parameters.values']
    },
    {
        nodeType: 'airtable',
        property: 'sort',
        subProperty: 'sortField',
        expectedStructure: 'sort.sortField array',
        invalidPatterns: ['sort.sortField.values']
    }
];
//# sourceMappingURL=fixed-collection-validator.js.map