"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TemplateSanitizer = exports.defaultSanitizerConfig = void 0;
const logger_1 = require("./logger");
exports.defaultSanitizerConfig = {
    problematicTokens: [],
    tokenPatterns: [
        /apify_api_[A-Za-z0-9]+/g,
        /sk-[A-Za-z0-9]+/g,
        /pat[A-Za-z0-9_]{40,}/g,
        /ghp_[A-Za-z0-9]{36,}/g,
        /gho_[A-Za-z0-9]{36,}/g,
        /Bearer\s+[A-Za-z0-9\-._~+\/]+=*/g
    ],
    replacements: new Map([
        ['apify_api_', 'apify_api_YOUR_TOKEN_HERE'],
        ['sk-', 'sk-YOUR_OPENAI_KEY_HERE'],
        ['pat', 'patYOUR_AIRTABLE_TOKEN_HERE'],
        ['ghp_', 'ghp_YOUR_GITHUB_TOKEN_HERE'],
        ['gho_', 'gho_YOUR_GITHUB_TOKEN_HERE'],
        ['Bearer ', 'Bearer YOUR_TOKEN_HERE']
    ])
};
class TemplateSanitizer {
    constructor(config = exports.defaultSanitizerConfig) {
        this.config = config;
    }
    addProblematicToken(token) {
        if (!this.config.problematicTokens.includes(token)) {
            this.config.problematicTokens.push(token);
            logger_1.logger.info(`Added problematic token to sanitizer: ${token.substring(0, 10)}...`);
        }
    }
    addTokenPattern(pattern, replacement) {
        this.config.tokenPatterns.push(pattern);
        const prefix = pattern.source.match(/^([^[]+)/)?.[1] || '';
        if (prefix) {
            this.config.replacements.set(prefix, replacement);
        }
    }
    sanitizeWorkflow(workflow) {
        if (!workflow) {
            return { sanitized: workflow, wasModified: false };
        }
        const original = JSON.stringify(workflow);
        let sanitized = this.sanitizeObject(workflow);
        if (sanitized && sanitized.pinData) {
            delete sanitized.pinData;
        }
        if (sanitized && sanitized.executionId) {
            delete sanitized.executionId;
        }
        if (sanitized && sanitized.staticData) {
            delete sanitized.staticData;
        }
        const wasModified = JSON.stringify(sanitized) !== original;
        return { sanitized, wasModified };
    }
    needsSanitization(workflow) {
        const workflowStr = JSON.stringify(workflow);
        for (const token of this.config.problematicTokens) {
            if (workflowStr.includes(token)) {
                return true;
            }
        }
        for (const pattern of this.config.tokenPatterns) {
            pattern.lastIndex = 0;
            if (pattern.test(workflowStr)) {
                return true;
            }
        }
        return false;
    }
    detectTokens(workflow) {
        const workflowStr = JSON.stringify(workflow);
        const detectedTokens = [];
        for (const token of this.config.problematicTokens) {
            if (workflowStr.includes(token)) {
                detectedTokens.push(token);
            }
        }
        for (const pattern of this.config.tokenPatterns) {
            pattern.lastIndex = 0;
            const matches = workflowStr.match(pattern);
            if (matches) {
                detectedTokens.push(...matches);
            }
        }
        return [...new Set(detectedTokens)];
    }
    sanitizeObject(obj) {
        if (typeof obj === 'string') {
            return this.replaceTokens(obj);
        }
        else if (Array.isArray(obj)) {
            return obj.map(item => this.sanitizeObject(item));
        }
        else if (obj && typeof obj === 'object') {
            const result = {};
            for (const key in obj) {
                result[key] = this.sanitizeObject(obj[key]);
            }
            return result;
        }
        return obj;
    }
    replaceTokens(str) {
        let result = str;
        this.config.problematicTokens.forEach(token => {
            result = result.replace(new RegExp(token, 'g'), 'YOUR_API_TOKEN_HERE');
        });
        this.config.tokenPatterns.forEach(pattern => {
            result = result.replace(pattern, (match) => {
                for (const [prefix, replacement] of this.config.replacements) {
                    if (match.startsWith(prefix)) {
                        return replacement;
                    }
                }
                return 'YOUR_TOKEN_HERE';
            });
        });
        return result;
    }
}
exports.TemplateSanitizer = TemplateSanitizer;
//# sourceMappingURL=template-sanitizer.js.map