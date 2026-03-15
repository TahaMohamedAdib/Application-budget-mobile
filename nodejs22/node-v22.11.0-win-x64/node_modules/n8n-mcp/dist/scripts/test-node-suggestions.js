#!/usr/bin/env npx tsx
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const database_adapter_1 = require("../database/database-adapter");
const node_repository_1 = require("../database/node-repository");
const node_similarity_service_1 = require("../services/node-similarity-service");
const workflow_validator_1 = require("../services/workflow-validator");
const enhanced_config_validator_1 = require("../services/enhanced-config-validator");
const workflow_auto_fixer_1 = require("../services/workflow-auto-fixer");
const logger_1 = require("../utils/logger");
const path_1 = __importDefault(require("path"));
const logger = new logger_1.Logger({ prefix: '[NodeSuggestions Test]' });
const console = {
    log: (msg) => logger.info(msg),
    error: (msg, err) => logger.error(msg, err)
};
async function testNodeSimilarity() {
    console.log('🔍 Testing Enhanced Node Type Suggestions\n');
    const dbPath = path_1.default.join(process.cwd(), 'data/nodes.db');
    const db = await (0, database_adapter_1.createDatabaseAdapter)(dbPath);
    const repository = new node_repository_1.NodeRepository(db);
    const similarityService = new node_similarity_service_1.NodeSimilarityService(repository);
    const validator = new workflow_validator_1.WorkflowValidator(repository, enhanced_config_validator_1.EnhancedConfigValidator);
    const testCases = [
        { invalid: 'HttpRequest', expected: 'nodes-base.httpRequest' },
        { invalid: 'HTTPRequest', expected: 'nodes-base.httpRequest' },
        { invalid: 'Webhook', expected: 'nodes-base.webhook' },
        { invalid: 'WebHook', expected: 'nodes-base.webhook' },
        { invalid: 'slack', expected: 'nodes-base.slack' },
        { invalid: 'googleSheets', expected: 'nodes-base.googleSheets' },
        { invalid: 'telegram', expected: 'nodes-base.telegram' },
        { invalid: 'htpRequest', expected: 'nodes-base.httpRequest' },
        { invalid: 'webook', expected: 'nodes-base.webhook' },
        { invalid: 'slak', expected: 'nodes-base.slack' },
        { invalid: 'http', expected: 'nodes-base.httpRequest' },
        { invalid: 'sheet', expected: 'nodes-base.googleSheets' },
        { invalid: 'nodes-base.openai', expected: 'nodes-langchain.openAi' },
        { invalid: 'n8n-nodes-base.httpRequest', expected: 'nodes-base.httpRequest' },
        { invalid: 'foobar', expected: null },
        { invalid: 'xyz123', expected: null },
    ];
    console.log('Testing individual node type suggestions:');
    console.log('='.repeat(60));
    for (const testCase of testCases) {
        const suggestions = await similarityService.findSimilarNodes(testCase.invalid, 3);
        console.log(`\n❌ Invalid type: "${testCase.invalid}"`);
        if (suggestions.length > 0) {
            console.log('✨ Suggestions:');
            for (const suggestion of suggestions) {
                const confidence = Math.round(suggestion.confidence * 100);
                const marker = suggestion.nodeType === testCase.expected ? '✅' : '  ';
                console.log(`${marker} ${suggestion.nodeType} (${confidence}% match) - ${suggestion.reason}`);
                if (suggestion.confidence >= 0.9) {
                    console.log('   💡 Can be auto-fixed!');
                }
            }
            if (testCase.expected) {
                const found = suggestions.some(s => s.nodeType === testCase.expected);
                if (!found) {
                    console.log(`   ⚠️  Expected "${testCase.expected}" was not suggested!`);
                }
            }
        }
        else {
            console.log('   No suggestions found');
            if (testCase.expected) {
                console.log(`   ⚠️  Expected "${testCase.expected}" was not suggested!`);
            }
        }
    }
    console.log('\n' + '='.repeat(60));
    console.log('\n📋 Testing workflow validation with unknown nodes:');
    console.log('='.repeat(60));
    const testWorkflow = {
        id: 'test-workflow',
        name: 'Test Workflow',
        nodes: [
            {
                id: '1',
                name: 'Start',
                type: 'nodes-base.manualTrigger',
                position: [100, 100],
                parameters: {},
                typeVersion: 1
            },
            {
                id: '2',
                name: 'HTTP Request',
                type: 'HTTPRequest',
                position: [300, 100],
                parameters: {},
                typeVersion: 1
            },
            {
                id: '3',
                name: 'Slack',
                type: 'slack',
                position: [500, 100],
                parameters: {},
                typeVersion: 1
            },
            {
                id: '4',
                name: 'Unknown',
                type: 'foobar',
                position: [700, 100],
                parameters: {},
                typeVersion: 1
            }
        ],
        connections: {
            'Start': {
                main: [[{ node: 'HTTP Request', type: 'main', index: 0 }]]
            },
            'HTTP Request': {
                main: [[{ node: 'Slack', type: 'main', index: 0 }]]
            },
            'Slack': {
                main: [[{ node: 'Unknown', type: 'main', index: 0 }]]
            }
        },
        settings: {}
    };
    const validationResult = await validator.validateWorkflow(testWorkflow, {
        validateNodes: true,
        validateConnections: false,
        validateExpressions: false,
        profile: 'runtime'
    });
    console.log('\nValidation Results:');
    for (const error of validationResult.errors) {
        if (error.message?.includes('Unknown node type:')) {
            console.log(`\n🔴 ${error.nodeName}: ${error.message}`);
        }
    }
    console.log('\n' + '='.repeat(60));
    console.log('\n🔧 Testing AutoFixer with node type corrections:');
    console.log('='.repeat(60));
    const autoFixer = new workflow_auto_fixer_1.WorkflowAutoFixer(repository);
    const fixResult = await autoFixer.generateFixes(testWorkflow, validationResult, [], {
        applyFixes: false,
        fixTypes: ['node-type-correction'],
        confidenceThreshold: 'high'
    });
    if (fixResult.fixes.length > 0) {
        console.log('\n✅ Auto-fixable issues found:');
        for (const fix of fixResult.fixes) {
            console.log(`   • ${fix.description}`);
        }
        console.log(`\nSummary: ${fixResult.summary}`);
    }
    else {
        console.log('\n❌ No auto-fixable node type issues found (only high-confidence fixes are applied)');
    }
    console.log('\n' + '='.repeat(60));
    console.log('\n✨ Test complete!');
}
testNodeSimilarity().catch(error => {
    console.error('Test failed:', error);
    process.exit(1);
});
//# sourceMappingURL=test-node-suggestions.js.map