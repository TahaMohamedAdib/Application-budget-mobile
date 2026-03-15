"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DocsMapper = void 0;
const fs_1 = require("fs");
const path_1 = __importDefault(require("path"));
class DocsMapper {
    constructor() {
        this.docsPath = path_1.default.join(process.cwd(), 'n8n-docs');
        this.KNOWN_FIXES = {
            'httpRequest': 'httprequest',
            'code': 'code',
            'webhook': 'webhook',
            'respondToWebhook': 'respondtowebhook',
            'n8n-nodes-base.httpRequest': 'httprequest',
            'n8n-nodes-base.code': 'code',
            'n8n-nodes-base.webhook': 'webhook',
            'n8n-nodes-base.respondToWebhook': 'respondtowebhook'
        };
    }
    async fetchDocumentation(nodeType) {
        const fixedType = this.KNOWN_FIXES[nodeType] || nodeType;
        const nodeName = fixedType.split('.').pop()?.toLowerCase();
        if (!nodeName) {
            console.log(`⚠️  Could not extract node name from: ${nodeType}`);
            return null;
        }
        console.log(`📄 Looking for docs for: ${nodeType} -> ${nodeName}`);
        const possiblePaths = [
            `docs/integrations/builtin/core-nodes/n8n-nodes-base.${nodeName}.md`,
            `docs/integrations/builtin/app-nodes/n8n-nodes-base.${nodeName}.md`,
            `docs/integrations/builtin/trigger-nodes/n8n-nodes-base.${nodeName}.md`,
            `docs/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.${nodeName}.md`,
            `docs/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.${nodeName}.md`,
            `docs/integrations/builtin/core-nodes/n8n-nodes-base.${nodeName}/index.md`,
            `docs/integrations/builtin/app-nodes/n8n-nodes-base.${nodeName}/index.md`,
            `docs/integrations/builtin/trigger-nodes/n8n-nodes-base.${nodeName}/index.md`,
            `docs/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.${nodeName}/index.md`,
            `docs/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.${nodeName}/index.md`
        ];
        for (const relativePath of possiblePaths) {
            try {
                const fullPath = path_1.default.join(this.docsPath, relativePath);
                let content = await fs_1.promises.readFile(fullPath, 'utf-8');
                console.log(`  ✓ Found docs at: ${relativePath}`);
                content = this.enhanceLoopNodeDocumentation(nodeType, content);
                return content;
            }
            catch (error) {
                continue;
            }
        }
        console.log(`  ✗ No docs found for ${nodeName}`);
        return null;
    }
    enhanceLoopNodeDocumentation(nodeType, content) {
        if (nodeType.includes('splitInBatches')) {
            const outputGuidance = `

## CRITICAL OUTPUT CONNECTION INFORMATION

**⚠️ OUTPUT INDICES ARE COUNTERINTUITIVE ⚠️**

The SplitInBatches node has TWO outputs with specific indices:
- **Output 0 (index 0) = "done"**: Receives final processed data when loop completes
- **Output 1 (index 1) = "loop"**: Receives current batch data during iteration

### Correct Connection Pattern:
1. Connect nodes that PROCESS items inside the loop to **Output 1 ("loop")**
2. Connect nodes that run AFTER the loop completes to **Output 0 ("done")**
3. The last processing node in the loop must connect back to the SplitInBatches node

### Common Mistake:
AI assistants often connect these backwards because the logical flow (loop first, then done) doesn't match the technical indices (done=0, loop=1).

`;
            const insertPoint = content.indexOf('## When to use');
            if (insertPoint > -1) {
                content = content.slice(0, insertPoint) + outputGuidance + content.slice(insertPoint);
            }
            else {
                content = outputGuidance + '\n' + content;
            }
        }
        if (nodeType.includes('.if')) {
            const outputGuidance = `

## Output Connection Information

The IF node has TWO outputs:
- **Output 0 (index 0) = "true"**: Items that match the condition
- **Output 1 (index 1) = "false"**: Items that do not match the condition

`;
            const insertPoint = content.indexOf('## Node parameters');
            if (insertPoint > -1) {
                content = content.slice(0, insertPoint) + outputGuidance + content.slice(insertPoint);
            }
        }
        return content;
    }
}
exports.DocsMapper = DocsMapper;
//# sourceMappingURL=docs-mapper.js.map