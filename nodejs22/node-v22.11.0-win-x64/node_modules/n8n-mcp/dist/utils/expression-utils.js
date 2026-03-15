"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isExpression = isExpression;
exports.containsExpression = containsExpression;
exports.shouldSkipLiteralValidation = shouldSkipLiteralValidation;
exports.extractExpressionContent = extractExpressionContent;
exports.hasMixedContent = hasMixedContent;
function isExpression(value) {
    return typeof value === 'string' && value.startsWith('=');
}
function containsExpression(value) {
    if (typeof value !== 'string') {
        return false;
    }
    return /\{\{.*\}\}/s.test(value);
}
function shouldSkipLiteralValidation(value) {
    return isExpression(value) || containsExpression(value);
}
function extractExpressionContent(value) {
    if (!isExpression(value)) {
        return value;
    }
    const withoutPrefix = value.substring(1);
    const match = withoutPrefix.match(/^\{\{(.+)\}\}$/s);
    if (match) {
        return match[1].trim();
    }
    return withoutPrefix;
}
function hasMixedContent(value) {
    if (typeof value !== 'string') {
        return false;
    }
    if (!containsExpression(value)) {
        return false;
    }
    const trimmed = value.trim();
    if (trimmed.startsWith('={{') && trimmed.endsWith('}}')) {
        const count = (trimmed.match(/\{\{/g) || []).length;
        if (count === 1) {
            return false;
        }
    }
    return true;
}
//# sourceMappingURL=expression-utils.js.map