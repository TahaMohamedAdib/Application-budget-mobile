#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const database_adapter_1 = require("../database/database-adapter");
const template_sanitizer_1 = require("../utils/template-sanitizer");
const zlib_1 = require("zlib");
async function sanitizeTemplates() {
    console.log('🧹 Sanitizing workflow templates in database...\n');
    const db = await (0, database_adapter_1.createDatabaseAdapter)('./data/nodes.db');
    const sanitizer = new template_sanitizer_1.TemplateSanitizer();
    try {
        const templates = db.prepare('SELECT id, name, workflow_json, workflow_json_compressed FROM templates').all();
        console.log(`Found ${templates.length} templates to check\n`);
        let sanitizedCount = 0;
        const problematicTemplates = [];
        for (const template of templates) {
            let originalWorkflow = null;
            let useCompressed = false;
            if (template.workflow_json_compressed) {
                try {
                    const buffer = Buffer.from(template.workflow_json_compressed, 'base64');
                    const decompressed = (0, zlib_1.gunzipSync)(buffer).toString('utf-8');
                    originalWorkflow = JSON.parse(decompressed);
                    useCompressed = true;
                }
                catch (e) {
                    console.log(`⚠️ Failed to decompress template ${template.id}, trying uncompressed`);
                }
            }
            if (!originalWorkflow && template.workflow_json) {
                try {
                    originalWorkflow = JSON.parse(template.workflow_json);
                }
                catch (e) {
                    console.log(`⚠️ Skipping template ${template.id}: Invalid JSON in both formats`);
                    continue;
                }
            }
            if (!originalWorkflow) {
                continue;
            }
            const { sanitized: sanitizedWorkflow, wasModified } = sanitizer.sanitizeWorkflow(originalWorkflow);
            if (wasModified) {
                const detectedTokens = sanitizer.detectTokens(originalWorkflow);
                if (useCompressed) {
                    const compressed = (0, zlib_1.gzipSync)(JSON.stringify(sanitizedWorkflow)).toString('base64');
                    const stmt = db.prepare('UPDATE templates SET workflow_json_compressed = ? WHERE id = ?');
                    stmt.run(compressed, template.id);
                }
                else {
                    const stmt = db.prepare('UPDATE templates SET workflow_json = ? WHERE id = ?');
                    stmt.run(JSON.stringify(sanitizedWorkflow), template.id);
                }
                sanitizedCount++;
                problematicTemplates.push({
                    id: template.id,
                    name: template.name,
                    tokens: detectedTokens
                });
                console.log(`✅ Sanitized template ${template.id}: ${template.name}`);
                detectedTokens.forEach(token => {
                    console.log(`   - Found: ${token.substring(0, 20)}...`);
                });
            }
        }
        console.log(`\n📊 Summary:`);
        console.log(`   Total templates: ${templates.length}`);
        console.log(`   Sanitized: ${sanitizedCount}`);
        if (problematicTemplates.length > 0) {
            console.log(`\n⚠️  Templates that contained API tokens:`);
            problematicTemplates.forEach(t => {
                console.log(`   - ${t.id}: ${t.name}`);
            });
        }
        console.log('\n✨ Sanitization complete!');
    }
    catch (error) {
        console.error('❌ Error sanitizing templates:', error);
        process.exit(1);
    }
    finally {
        db.close();
    }
}
if (require.main === module) {
    sanitizeTemplates().catch(console.error);
}
//# sourceMappingURL=sanitize-templates.js.map