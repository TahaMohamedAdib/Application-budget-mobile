"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TemplateFetcher = void 0;
const axios_1 = __importDefault(require("axios"));
const logger_1 = require("../utils/logger");
class TemplateFetcher {
    constructor() {
        this.baseUrl = 'https://api.n8n.io/api/templates';
        this.pageSize = 250;
        this.maxRetries = 3;
        this.retryDelay = 1000;
    }
    async retryWithBackoff(fn, context, maxRetries = this.maxRetries) {
        let lastError;
        for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                return await fn();
            }
            catch (error) {
                lastError = error;
                if (attempt < maxRetries) {
                    const delay = this.retryDelay * attempt;
                    logger_1.logger.warn(`${context} - Attempt ${attempt}/${maxRetries} failed, retrying in ${delay}ms...`);
                    await this.sleep(delay);
                }
            }
        }
        logger_1.logger.error(`${context} - All ${maxRetries} attempts failed, skipping`, lastError);
        return null;
    }
    async fetchTemplates(progressCallback, sinceDate) {
        const allTemplates = await this.fetchAllTemplates(progressCallback);
        const cutoffDate = sinceDate || (() => {
            const oneYearAgo = new Date();
            oneYearAgo.setMonth(oneYearAgo.getMonth() - 12);
            return oneYearAgo;
        })();
        const recentTemplates = allTemplates.filter((w) => {
            const createdDate = new Date(w.createdAt);
            return createdDate >= cutoffDate;
        });
        logger_1.logger.info(`Filtered to ${recentTemplates.length} templates since ${cutoffDate.toISOString().split('T')[0]} (out of ${allTemplates.length} total)`);
        return recentTemplates;
    }
    async fetchAllTemplates(progressCallback) {
        const allTemplates = [];
        let page = 1;
        let hasMore = true;
        let totalWorkflows = 0;
        logger_1.logger.info('Starting complete template fetch from n8n.io API');
        while (hasMore) {
            const result = await this.retryWithBackoff(async () => {
                const response = await axios_1.default.get(`${this.baseUrl}/search`, {
                    params: {
                        page,
                        rows: this.pageSize
                    }
                });
                return response.data;
            }, `Fetching templates page ${page}`);
            if (result === null) {
                logger_1.logger.warn(`Skipping page ${page} after ${this.maxRetries} failed attempts`);
                page++;
                continue;
            }
            const { workflows } = result;
            totalWorkflows = result.totalWorkflows || totalWorkflows;
            allTemplates.push(...workflows);
            const totalPages = Math.ceil(totalWorkflows / this.pageSize);
            if (progressCallback) {
                progressCallback(allTemplates.length, totalWorkflows);
            }
            logger_1.logger.debug(`Fetched page ${page}/${totalPages}: ${workflows.length} templates (total so far: ${allTemplates.length}/${totalWorkflows})`);
            if (workflows.length < this.pageSize) {
                hasMore = false;
            }
            page++;
            if (hasMore) {
                await this.sleep(300);
            }
        }
        logger_1.logger.info(`Fetched all ${allTemplates.length} templates from n8n.io`);
        return allTemplates;
    }
    async fetchTemplateDetail(workflowId) {
        const result = await this.retryWithBackoff(async () => {
            const response = await axios_1.default.get(`${this.baseUrl}/workflows/${workflowId}`);
            return response.data.workflow;
        }, `Fetching template detail for workflow ${workflowId}`);
        return result;
    }
    async fetchAllTemplateDetails(workflows, progressCallback) {
        const details = new Map();
        let skipped = 0;
        logger_1.logger.info(`Fetching details for ${workflows.length} templates`);
        for (let i = 0; i < workflows.length; i++) {
            const workflow = workflows[i];
            const detail = await this.fetchTemplateDetail(workflow.id);
            if (detail !== null) {
                details.set(workflow.id, detail);
            }
            else {
                skipped++;
                logger_1.logger.warn(`Skipped workflow ${workflow.id} after ${this.maxRetries} failed attempts`);
            }
            if (progressCallback) {
                progressCallback(i + 1, workflows.length);
            }
            await this.sleep(150);
        }
        logger_1.logger.info(`Successfully fetched ${details.size} template details (${skipped} skipped)`);
        return details;
    }
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
exports.TemplateFetcher = TemplateFetcher;
//# sourceMappingURL=template-fetcher.js.map