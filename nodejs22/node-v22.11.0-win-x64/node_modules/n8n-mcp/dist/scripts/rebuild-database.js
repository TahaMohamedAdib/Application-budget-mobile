#!/usr/bin/env node
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
exports.rebuildDocumentationDatabase = rebuildDocumentationDatabase;
const dotenv = __importStar(require("dotenv"));
const node_documentation_service_1 = require("../services/node-documentation-service");
dotenv.config();
async function rebuildDocumentationDatabase() {
    console.log('🔄 Starting enhanced documentation database rebuild...\n');
    const startTime = Date.now();
    const service = new node_documentation_service_1.NodeDocumentationService();
    try {
        const results = await service.rebuildDatabase();
        const duration = ((Date.now() - startTime) / 1000).toFixed(2);
        console.log('\n✅ Enhanced documentation database rebuild completed!\n');
        console.log('📊 Results:');
        console.log(`   Total nodes found: ${results.total}`);
        console.log(`   Successfully processed: ${results.successful}`);
        console.log(`   Failed: ${results.failed}`);
        console.log(`   Duration: ${duration}s`);
        if (results.errors.length > 0) {
            console.log(`\n⚠️  First ${Math.min(5, results.errors.length)} errors:`);
            results.errors.slice(0, 5).forEach(err => {
                console.log(`   - ${err}`);
            });
            if (results.errors.length > 5) {
                console.log(`   ... and ${results.errors.length - 5} more errors`);
            }
        }
        const stats = await service.getStatistics();
        console.log('\n📈 Database Statistics:');
        console.log(`   Total nodes: ${stats.totalNodes}`);
        console.log(`   Nodes with documentation: ${stats.nodesWithDocs}`);
        console.log(`   Nodes with examples: ${stats.nodesWithExamples}`);
        console.log(`   Nodes with credentials: ${stats.nodesWithCredentials}`);
        console.log(`   Trigger nodes: ${stats.triggerNodes}`);
        console.log(`   Webhook nodes: ${stats.webhookNodes}`);
        console.log('\n📦 Package distribution:');
        stats.packageDistribution.slice(0, 10).forEach((pkg) => {
            console.log(`   ${pkg.package}: ${pkg.count} nodes`);
        });
        await service.close();
        console.log('\n✨ Enhanced documentation database is ready!');
        console.log('💡 The database now includes:');
        console.log('   - Complete node source code');
        console.log('   - Enhanced documentation with operations and API methods');
        console.log('   - Code examples and templates');
        console.log('   - Related resources and required scopes');
    }
    catch (error) {
        console.error('\n❌ Documentation database rebuild failed:', error);
        service.close();
        process.exit(1);
    }
}
if (require.main === module) {
    rebuildDocumentationDatabase().catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
}
//# sourceMappingURL=rebuild-database.js.map