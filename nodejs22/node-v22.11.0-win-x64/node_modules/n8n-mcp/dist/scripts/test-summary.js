#!/usr/bin/env npx tsx
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const database_adapter_1 = require("../database/database-adapter");
const node_repository_1 = require("../database/node-repository");
const node_similarity_service_1 = require("../services/node-similarity-service");
const path_1 = __importDefault(require("path"));
async function testSummary() {
    const dbPath = path_1.default.join(process.cwd(), 'data/nodes.db');
    const db = await (0, database_adapter_1.createDatabaseAdapter)(dbPath);
    const repository = new node_repository_1.NodeRepository(db);
    const similarityService = new node_similarity_service_1.NodeSimilarityService(repository);
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
    let passed = 0;
    let failed = 0;
    console.log('Test Results Summary:');
    console.log('='.repeat(60));
    for (const testCase of testCases) {
        const suggestions = await similarityService.findSimilarNodes(testCase.invalid, 3);
        let result = '❌';
        let status = 'FAILED';
        if (testCase.expected === null) {
            if (suggestions.length === 0) {
                result = '✅';
                status = 'PASSED';
                passed++;
            }
            else {
                failed++;
            }
        }
        else {
            const found = suggestions.some(s => s.nodeType === testCase.expected);
            if (found) {
                const suggestion = suggestions.find(s => s.nodeType === testCase.expected);
                const isAutoFixable = suggestion && suggestion.confidence >= 0.9;
                result = '✅';
                status = isAutoFixable ? 'PASSED (auto-fixable)' : 'PASSED';
                passed++;
            }
            else {
                failed++;
            }
        }
        console.log(`${result} "${testCase.invalid}" → ${testCase.expected || 'no suggestions'}: ${status}`);
    }
    console.log('='.repeat(60));
    console.log(`\nTotal: ${passed}/${testCases.length} tests passed`);
    if (failed === 0) {
        console.log('🎉 All tests passed!');
    }
    else {
        console.log(`⚠️  ${failed} tests failed`);
    }
}
testSummary().catch(console.error);
//# sourceMappingURL=test-summary.js.map