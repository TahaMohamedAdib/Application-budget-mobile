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
async function debugHttpSearch() {
    const dbPath = path_1.default.join(process.cwd(), 'data/nodes.db');
    const db = await (0, database_adapter_1.createDatabaseAdapter)(dbPath);
    const repository = new node_repository_1.NodeRepository(db);
    const service = new node_similarity_service_1.NodeSimilarityService(repository);
    console.log('Testing "http" search...\n');
    const httpNode = repository.getNode('nodes-base.httpRequest');
    console.log('HTTP Request node exists:', httpNode ? 'Yes' : 'No');
    if (httpNode) {
        console.log('  Display name:', httpNode.displayName);
    }
    const suggestions = await service.findSimilarNodes('http', 5);
    console.log('\nSuggestions for "http":', suggestions.length);
    suggestions.forEach(s => {
        console.log(`  - ${s.nodeType} (${Math.round(s.confidence * 100)}%)`);
    });
    console.log('\nManual score calculation for httpRequest:');
    const testNode = {
        nodeType: 'nodes-base.httpRequest',
        displayName: 'HTTP Request',
        category: 'Core Nodes'
    };
    const cleanInvalid = 'http';
    const cleanValid = 'nodesbasehttprequest';
    const displayNameClean = 'httprequest';
    const hasSubstring = cleanValid.includes(cleanInvalid) || displayNameClean.includes(cleanInvalid);
    console.log(`  Substring match: ${hasSubstring}`);
    const patternScore = hasSubstring ? 35 : 0;
    console.log(`  Pattern score: ${patternScore}`);
    console.log(`  Total score would need to be >= 50 to appear`);
    const allNodes = repository.getAllNodes();
    const httpNodes = allNodes.filter(n => n.nodeType.toLowerCase().includes('http') ||
        (n.displayName && n.displayName.toLowerCase().includes('http')));
    console.log('\n\nNodes containing "http" in name:');
    httpNodes.slice(0, 5).forEach(n => {
        console.log(`  - ${n.nodeType} (${n.displayName})`);
        const normalizedSearch = 'http';
        const normalizedType = n.nodeType.toLowerCase().replace(/[^a-z0-9]/g, '');
        const normalizedDisplay = (n.displayName || '').toLowerCase().replace(/[^a-z0-9]/g, '');
        const containsInType = normalizedType.includes(normalizedSearch);
        const containsInDisplay = normalizedDisplay.includes(normalizedSearch);
        console.log(`    Type check: "${normalizedType}" includes "${normalizedSearch}" = ${containsInType}`);
        console.log(`    Display check: "${normalizedDisplay}" includes "${normalizedSearch}" = ${containsInDisplay}`);
    });
}
debugHttpSearch().catch(console.error);
//# sourceMappingURL=debug-http-search.js.map