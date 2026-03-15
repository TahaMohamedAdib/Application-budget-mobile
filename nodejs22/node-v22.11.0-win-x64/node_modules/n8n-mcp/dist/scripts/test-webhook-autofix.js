#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const node_repository_1 = require("../database/node-repository");
const database_adapter_1 = require("../database/database-adapter");
const workflow_auto_fixer_1 = require("../services/workflow-auto-fixer");
const workflow_validator_1 = require("../services/workflow-validator");
const enhanced_config_validator_1 = require("../services/enhanced-config-validator");
const logger_1 = require("../utils/logger");
const path_1 = require("path");
const logger = new logger_1.Logger({ prefix: '[TestWebhookAutofix]' });
const testWorkflow = {
    id: 'test_webhook_fix',
    name: 'Test Webhook Autofix',
    active: false,
    nodes: [
        {
            id: '1',
            name: 'Webhook',
            type: 'n8n-nodes-base.webhook',
            typeVersion: 2.1,
            position: [250, 300],
            parameters: {},
        },
        {
            id: '2',
            name: 'HTTP Request',
            type: 'n8n-nodes-base.httpRequest',
            typeVersion: 4.2,
            position: [450, 300],
            parameters: {
                url: 'https://api.example.com/data',
                method: 'GET'
            }
        }
    ],
    connections: {
        'Webhook': {
            main: [[{
                        node: 'HTTP Request',
                        type: 'main',
                        index: 0
                    }]]
        }
    },
    settings: {
        executionOrder: 'v1'
    },
    staticData: undefined
};
async function testWebhookAutofix() {
    logger.info('Testing webhook path autofixer...');
    const dbPath = (0, path_1.join)(process.cwd(), 'data', 'nodes.db');
    const adapter = await (0, database_adapter_1.createDatabaseAdapter)(dbPath);
    const repository = new node_repository_1.NodeRepository(adapter);
    const validator = new workflow_validator_1.WorkflowValidator(repository, enhanced_config_validator_1.EnhancedConfigValidator);
    const autoFixer = new workflow_auto_fixer_1.WorkflowAutoFixer(repository);
    logger.info('Step 1: Validating workflow to identify issues...');
    const validationResult = await validator.validateWorkflow(testWorkflow);
    console.log('\n📋 Validation Summary:');
    console.log(`- Valid: ${validationResult.valid}`);
    console.log(`- Errors: ${validationResult.errors.length}`);
    console.log(`- Warnings: ${validationResult.warnings.length}`);
    if (validationResult.errors.length > 0) {
        console.log('\n❌ Errors found:');
        validationResult.errors.forEach(error => {
            console.log(`  - [${error.nodeName || error.nodeId}] ${error.message}`);
        });
    }
    logger.info('\nStep 2: Generating fixes in preview mode...');
    const fixResult = await autoFixer.generateFixes(testWorkflow, validationResult, [], {
        applyFixes: false,
        fixTypes: ['webhook-missing-path']
    });
    console.log('\n🔧 Fix Results:');
    console.log(`- Summary: ${fixResult.summary}`);
    console.log(`- Total fixes: ${fixResult.stats.total}`);
    console.log(`- Webhook path fixes: ${fixResult.stats.byType['webhook-missing-path']}`);
    if (fixResult.fixes.length > 0) {
        console.log('\n📝 Detailed Fixes:');
        fixResult.fixes.forEach(fix => {
            console.log(`  - Node: ${fix.node}`);
            console.log(`    Field: ${fix.field}`);
            console.log(`    Type: ${fix.type}`);
            console.log(`    Before: ${fix.before || 'undefined'}`);
            console.log(`    After: ${fix.after}`);
            console.log(`    Confidence: ${fix.confidence}`);
            console.log(`    Description: ${fix.description}`);
        });
    }
    if (fixResult.operations.length > 0) {
        console.log('\n🔄 Operations to Apply:');
        fixResult.operations.forEach(op => {
            if (op.type === 'updateNode') {
                console.log(`  - Update Node: ${op.nodeId}`);
                console.log(`    Updates: ${JSON.stringify(op.updates, null, 2)}`);
            }
        });
    }
    if (fixResult.fixes.length > 0) {
        const webhookFix = fixResult.fixes.find(f => f.type === 'webhook-missing-path');
        if (webhookFix) {
            const uuid = webhookFix.after;
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            const isValidUUID = uuidRegex.test(uuid);
            console.log('\n✅ UUID Validation:');
            console.log(`  - Generated UUID: ${uuid}`);
            console.log(`  - Valid format: ${isValidUUID ? 'Yes' : 'No'}`);
        }
    }
    logger.info('\n✨ Webhook autofix test completed successfully!');
}
testWebhookAutofix().catch(error => {
    logger.error('Test failed:', error);
    process.exit(1);
});
//# sourceMappingURL=test-webhook-autofix.js.map