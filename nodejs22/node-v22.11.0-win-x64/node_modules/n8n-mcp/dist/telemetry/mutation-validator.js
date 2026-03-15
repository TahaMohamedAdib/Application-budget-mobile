"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mutationValidator = exports.MutationValidator = exports.DEFAULT_MUTATION_TRACKING_OPTIONS = void 0;
const crypto_1 = require("crypto");
exports.DEFAULT_MUTATION_TRACKING_OPTIONS = {
    enabled: true,
    maxWorkflowSizeKb: 500,
    validateQuality: true,
    sanitize: true,
};
class MutationValidator {
    constructor(options = {}) {
        this.options = { ...exports.DEFAULT_MUTATION_TRACKING_OPTIONS, ...options };
    }
    validate(data) {
        const errors = [];
        const warnings = [];
        if (!this.isValidWorkflow(data.workflowBefore)) {
            errors.push('Invalid workflow_before structure');
        }
        if (!this.isValidWorkflow(data.workflowAfter)) {
            errors.push('Invalid workflow_after structure');
        }
        const beforeSizeKb = this.getWorkflowSizeKb(data.workflowBefore);
        const afterSizeKb = this.getWorkflowSizeKb(data.workflowAfter);
        if (beforeSizeKb > this.options.maxWorkflowSizeKb) {
            errors.push(`workflow_before size (${beforeSizeKb}KB) exceeds maximum (${this.options.maxWorkflowSizeKb}KB)`);
        }
        if (afterSizeKb > this.options.maxWorkflowSizeKb) {
            errors.push(`workflow_after size (${afterSizeKb}KB) exceeds maximum (${this.options.maxWorkflowSizeKb}KB)`);
        }
        if (!this.hasMeaningfulChange(data.workflowBefore, data.workflowAfter)) {
            warnings.push('No meaningful change detected between before and after workflows');
        }
        if (!data.userIntent || data.userIntent.trim().length === 0) {
            warnings.push('User intent is empty');
        }
        else if (data.userIntent.trim().length < 5) {
            warnings.push('User intent is too short (less than 5 characters)');
        }
        else if (data.userIntent.length > 1000) {
            warnings.push('User intent is very long (over 1000 characters)');
        }
        if (!data.operations || data.operations.length === 0) {
            errors.push('No operations provided');
        }
        if (data.validationBefore && data.validationAfter) {
            if (typeof data.validationBefore.valid !== 'boolean') {
                warnings.push('Invalid validation_before structure');
            }
            if (typeof data.validationAfter.valid !== 'boolean') {
                warnings.push('Invalid validation_after structure');
            }
        }
        if (data.durationMs !== undefined) {
            if (data.durationMs < 0) {
                errors.push('Duration cannot be negative');
            }
            if (data.durationMs > 300000) {
                warnings.push('Duration is very long (over 5 minutes)');
            }
        }
        return {
            valid: errors.length === 0,
            errors,
            warnings,
        };
    }
    isValidWorkflow(workflow) {
        if (!workflow || typeof workflow !== 'object') {
            return false;
        }
        if (!Array.isArray(workflow.nodes)) {
            return false;
        }
        if (!workflow.connections || typeof workflow.connections !== 'object') {
            return false;
        }
        return true;
    }
    getWorkflowSizeKb(workflow) {
        try {
            const json = JSON.stringify(workflow);
            return json.length / 1024;
        }
        catch {
            return 0;
        }
    }
    hasMeaningfulChange(workflowBefore, workflowAfter) {
        try {
            const hashBefore = this.hashWorkflow(workflowBefore);
            const hashAfter = this.hashWorkflow(workflowAfter);
            return hashBefore !== hashAfter;
        }
        catch {
            return false;
        }
    }
    hashWorkflow(workflow) {
        try {
            const json = JSON.stringify(workflow);
            return (0, crypto_1.createHash)('sha256').update(json).digest('hex').substring(0, 16);
        }
        catch {
            return '';
        }
    }
    shouldExclude(data) {
        if (!data.mutationSuccess && !data.mutationError) {
            return true;
        }
        if (!this.hasMeaningfulChange(data.workflowBefore, data.workflowAfter)) {
            return true;
        }
        const beforeSizeKb = this.getWorkflowSizeKb(data.workflowBefore);
        const afterSizeKb = this.getWorkflowSizeKb(data.workflowAfter);
        if (beforeSizeKb > this.options.maxWorkflowSizeKb ||
            afterSizeKb > this.options.maxWorkflowSizeKb) {
            return true;
        }
        return false;
    }
    isDuplicate(workflowBefore, workflowAfter, operations, recentMutations) {
        const hashBefore = this.hashWorkflow(workflowBefore);
        const hashAfter = this.hashWorkflow(workflowAfter);
        const operationsHash = this.hashOperations(operations);
        return recentMutations.some((m) => m.hashBefore === hashBefore &&
            m.hashAfter === hashAfter &&
            this.hashOperations(m.operations) === operationsHash);
    }
    hashOperations(operations) {
        try {
            const json = JSON.stringify(operations);
            return (0, crypto_1.createHash)('sha256').update(json).digest('hex').substring(0, 16);
        }
        catch {
            return '';
        }
    }
}
exports.MutationValidator = MutationValidator;
exports.mutationValidator = new MutationValidator();
//# sourceMappingURL=mutation-validator.js.map