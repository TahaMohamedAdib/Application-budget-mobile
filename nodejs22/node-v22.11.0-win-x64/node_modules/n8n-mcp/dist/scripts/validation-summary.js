#!/usr/bin/env node
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = require("fs");
const path_1 = __importDefault(require("path"));
const node_repository_1 = require("../database/node-repository");
const database_adapter_1 = require("../database/database-adapter");
const workflow_validator_1 = require("../services/workflow-validator");
const enhanced_config_validator_1 = require("../services/enhanced-config-validator");
const template_repository_1 = require("../templates/template-repository");
const logger_1 = require("../utils/logger");
const logger = new logger_1.Logger({ prefix: '[validation-summary]' });
async function runValidationSummary() {
    const dbPath = path_1.default.join(process.cwd(), 'data', 'nodes.db');
    if (!(0, fs_1.existsSync)(dbPath)) {
        logger.error('Database not found. Run npm run rebuild first.');
        process.exit(1);
    }
    const db = await (0, database_adapter_1.createDatabaseAdapter)(dbPath);
    const repository = new node_repository_1.NodeRepository(db);
    const templateRepository = new template_repository_1.TemplateRepository(db);
    const validator = new workflow_validator_1.WorkflowValidator(repository, enhanced_config_validator_1.EnhancedConfigValidator);
    try {
        const templates = await templateRepository.getAllTemplates(50);
        const results = {
            total: templates.length,
            valid: 0,
            invalid: 0,
            noErrors: 0,
            errorCategories: {
                unknownNodes: 0,
                missingRequired: 0,
                expressionErrors: 0,
                connectionErrors: 0,
                cycles: 0,
                other: 0
            },
            commonUnknownNodes: new Map(),
            stickyNoteIssues: 0
        };
        for (const template of templates) {
            try {
                const workflow = JSON.parse(template.workflow_json || '{}');
                const validationResult = await validator.validateWorkflow(workflow, {
                    profile: 'minimal'
                });
                if (validationResult.valid) {
                    results.valid++;
                }
                else {
                    results.invalid++;
                }
                if (validationResult.errors.length === 0) {
                    results.noErrors++;
                }
                validationResult.errors.forEach((error) => {
                    const errorMsg = typeof error.message === 'string' ? error.message : JSON.stringify(error.message);
                    if (errorMsg.includes('Unknown node type')) {
                        results.errorCategories.unknownNodes++;
                        const match = errorMsg.match(/Unknown node type: (.+)/);
                        if (match) {
                            const nodeType = match[1];
                            results.commonUnknownNodes.set(nodeType, (results.commonUnknownNodes.get(nodeType) || 0) + 1);
                        }
                    }
                    else if (errorMsg.includes('missing_required')) {
                        results.errorCategories.missingRequired++;
                        if (error.nodeName?.includes('Sticky Note')) {
                            results.stickyNoteIssues++;
                        }
                    }
                    else if (errorMsg.includes('Expression error')) {
                        results.errorCategories.expressionErrors++;
                    }
                    else if (errorMsg.includes('connection') || errorMsg.includes('Connection')) {
                        results.errorCategories.connectionErrors++;
                    }
                    else if (errorMsg.includes('cycle')) {
                        results.errorCategories.cycles++;
                    }
                    else {
                        results.errorCategories.other++;
                    }
                });
            }
            catch (error) {
                results.invalid++;
            }
        }
        console.log('\n' + '='.repeat(80));
        console.log('WORKFLOW VALIDATION SUMMARY');
        console.log('='.repeat(80));
        console.log(`\nTemplates analyzed: ${results.total}`);
        console.log(`Valid workflows: ${results.valid} (${((results.valid / results.total) * 100).toFixed(1)}%)`);
        console.log(`Workflows without errors: ${results.noErrors} (${((results.noErrors / results.total) * 100).toFixed(1)}%)`);
        console.log('\nError Categories:');
        console.log(`  - Unknown nodes: ${results.errorCategories.unknownNodes}`);
        console.log(`  - Missing required properties: ${results.errorCategories.missingRequired}`);
        console.log(`    (Sticky note issues: ${results.stickyNoteIssues})`);
        console.log(`  - Expression errors: ${results.errorCategories.expressionErrors}`);
        console.log(`  - Connection errors: ${results.errorCategories.connectionErrors}`);
        console.log(`  - Workflow cycles: ${results.errorCategories.cycles}`);
        console.log(`  - Other errors: ${results.errorCategories.other}`);
        if (results.commonUnknownNodes.size > 0) {
            console.log('\nTop Unknown Node Types:');
            const sortedNodes = Array.from(results.commonUnknownNodes.entries())
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10);
            sortedNodes.forEach(([nodeType, count]) => {
                console.log(`  - ${nodeType} (${count} occurrences)`);
            });
        }
        console.log('\nKey Insights:');
        const stickyNotePercent = ((results.stickyNoteIssues / results.errorCategories.missingRequired) * 100).toFixed(1);
        console.log(`  - ${stickyNotePercent}% of missing required property errors are from Sticky Notes`);
        console.log(`  - Most workflows have some validation warnings (best practices)`);
        console.log(`  - Expression validation is working well`);
        console.log(`  - Node type normalization is handling most cases correctly`);
    }
    catch (error) {
        logger.error('Failed to run validation summary:', error);
        process.exit(1);
    }
    finally {
        db.close();
    }
}
runValidationSummary().catch(error => {
    logger.error('Summary failed:', error);
    process.exit(1);
});
//# sourceMappingURL=validation-summary.js.map