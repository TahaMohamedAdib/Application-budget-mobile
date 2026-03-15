"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const workflow_auto_fixer_1 = require("../services/workflow-auto-fixer");
const workflow_validator_1 = require("../services/workflow-validator");
const enhanced_config_validator_1 = require("../services/enhanced-config-validator");
const expression_format_validator_1 = require("../services/expression-format-validator");
const node_repository_1 = require("../database/node-repository");
const logger_1 = require("../utils/logger");
const database_adapter_1 = require("../database/database-adapter");
const path = __importStar(require("path"));
const logger = new logger_1.Logger({ prefix: '[TestAutofix]' });
async function testAutofix() {
    const dbPath = path.join(__dirname, '../../data/nodes.db');
    const dbAdapter = await (0, database_adapter_1.createDatabaseAdapter)(dbPath);
    const repository = new node_repository_1.NodeRepository(dbAdapter);
    const testWorkflow = {
        id: 'test_workflow_1',
        name: 'Test Workflow for Autofix',
        nodes: [
            {
                id: 'webhook_1',
                name: 'Webhook',
                type: 'n8n-nodes-base.webhook',
                typeVersion: 1.1,
                position: [250, 300],
                parameters: {
                    httpMethod: 'GET',
                    path: 'test-webhook',
                    responseMode: 'onReceived',
                    responseData: 'firstEntryJson'
                }
            },
            {
                id: 'http_1',
                name: 'HTTP Request',
                type: 'n8n-nodes-base.httpRequest',
                typeVersion: 5.0,
                position: [450, 300],
                parameters: {
                    method: 'GET',
                    url: '{{ $json.webhookUrl }}',
                    sendHeaders: true,
                    headerParameters: {
                        parameters: [
                            {
                                name: 'Authorization',
                                value: '{{ $json.token }}'
                            }
                        ]
                    }
                },
                onError: 'continueErrorOutput'
            },
            {
                id: 'set_1',
                name: 'Set',
                type: 'n8n-nodes-base.set',
                typeVersion: 3.5,
                position: [650, 300],
                parameters: {
                    mode: 'manual',
                    duplicateItem: false,
                    values: {
                        values: [
                            {
                                name: 'status',
                                value: '{{ $json.success }}'
                            }
                        ]
                    }
                }
            }
        ],
        connections: {
            'Webhook': {
                main: [
                    [
                        {
                            node: 'HTTP Request',
                            type: 'main',
                            index: 0
                        }
                    ]
                ]
            },
            'HTTP Request': {
                main: [
                    [
                        {
                            node: 'Set',
                            type: 'main',
                            index: 0
                        }
                    ]
                ]
            }
        }
    };
    logger.info('=== Testing Workflow Auto-Fixer ===\n');
    logger.info('Step 1: Validating workflow to identify issues...');
    const validator = new workflow_validator_1.WorkflowValidator(repository, enhanced_config_validator_1.EnhancedConfigValidator);
    const validationResult = await validator.validateWorkflow(testWorkflow, {
        validateNodes: true,
        validateConnections: true,
        validateExpressions: true,
        profile: 'ai-friendly'
    });
    logger.info(`Found ${validationResult.errors.length} errors and ${validationResult.warnings.length} warnings`);
    logger.info('\nStep 2: Checking for expression format issues...');
    const allFormatIssues = [];
    for (const node of testWorkflow.nodes) {
        const formatContext = {
            nodeType: node.type,
            nodeName: node.name,
            nodeId: node.id
        };
        const nodeFormatIssues = expression_format_validator_1.ExpressionFormatValidator.validateNodeParameters(node.parameters, formatContext);
        const enrichedIssues = nodeFormatIssues.map(issue => ({
            ...issue,
            nodeName: node.name,
            nodeId: node.id
        }));
        allFormatIssues.push(...enrichedIssues);
    }
    logger.info(`Found ${allFormatIssues.length} expression format issues`);
    if (allFormatIssues.length > 0) {
        logger.info('\nExpression format issues found:');
        for (const issue of allFormatIssues) {
            logger.info(`  - ${issue.fieldPath}: ${issue.issueType} (${issue.severity})`);
            logger.info(`    Current: ${JSON.stringify(issue.currentValue)}`);
            logger.info(`    Fixed: ${JSON.stringify(issue.correctedValue)}`);
        }
    }
    logger.info('\nStep 3: Generating fixes (preview mode)...');
    const autoFixer = new workflow_auto_fixer_1.WorkflowAutoFixer();
    const previewResult = await autoFixer.generateFixes(testWorkflow, validationResult, allFormatIssues, {
        applyFixes: false,
        confidenceThreshold: 'medium'
    });
    logger.info(`\nGenerated ${previewResult.fixes.length} fixes:`);
    logger.info(`Summary: ${previewResult.summary}`);
    logger.info('\nFixes by type:');
    for (const [type, count] of Object.entries(previewResult.stats.byType)) {
        if (count > 0) {
            logger.info(`  - ${type}: ${count}`);
        }
    }
    logger.info('\nFixes by confidence:');
    for (const [confidence, count] of Object.entries(previewResult.stats.byConfidence)) {
        if (count > 0) {
            logger.info(`  - ${confidence}: ${count}`);
        }
    }
    logger.info('\nDetailed fixes:');
    for (const fix of previewResult.fixes) {
        logger.info(`\n[${fix.confidence.toUpperCase()}] ${fix.node}.${fix.field} (${fix.type})`);
        logger.info(`  Before: ${JSON.stringify(fix.before)}`);
        logger.info(`  After:  ${JSON.stringify(fix.after)}`);
        logger.info(`  Description: ${fix.description}`);
    }
    logger.info('\n\nGenerated diff operations:');
    for (const op of previewResult.operations) {
        logger.info(`\nOperation: ${op.type}`);
        logger.info(`  Details: ${JSON.stringify(op, null, 2)}`);
    }
    logger.info('\n\n=== Testing Different Confidence Thresholds ===');
    for (const threshold of ['high', 'medium', 'low']) {
        const result = await autoFixer.generateFixes(testWorkflow, validationResult, allFormatIssues, {
            applyFixes: false,
            confidenceThreshold: threshold
        });
        logger.info(`\nThreshold "${threshold}": ${result.fixes.length} fixes`);
    }
    logger.info('\n\n=== Testing Specific Fix Types ===');
    const fixTypes = ['expression-format', 'typeversion-correction', 'error-output-config'];
    for (const fixType of fixTypes) {
        const result = await autoFixer.generateFixes(testWorkflow, validationResult, allFormatIssues, {
            applyFixes: false,
            fixTypes: [fixType]
        });
        logger.info(`\nFix type "${fixType}": ${result.fixes.length} fixes`);
    }
    logger.info('\n\n✅ Autofix test completed successfully!');
    await dbAdapter.close();
}
testAutofix().catch(error => {
    logger.error('Test failed:', error);
    process.exit(1);
});
//# sourceMappingURL=test-autofix-workflow.js.map