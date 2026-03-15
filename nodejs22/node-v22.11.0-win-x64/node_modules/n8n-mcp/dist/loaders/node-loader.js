"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.N8nNodeLoader = void 0;
const path_1 = __importDefault(require("path"));
class N8nNodeLoader {
    constructor() {
        this.CORE_PACKAGES = [
            { name: 'n8n-nodes-base', path: 'n8n-nodes-base' },
            { name: '@n8n/n8n-nodes-langchain', path: '@n8n/n8n-nodes-langchain' }
        ];
    }
    async loadAllNodes() {
        const results = [];
        for (const pkg of this.CORE_PACKAGES) {
            try {
                console.log(`\n📦 Loading package: ${pkg.name} from ${pkg.path}`);
                const packageJson = require(`${pkg.path}/package.json`);
                console.log(`  Found ${Object.keys(packageJson.n8n?.nodes || {}).length} nodes in package.json`);
                const nodes = await this.loadPackageNodes(pkg.name, pkg.path, packageJson);
                results.push(...nodes);
            }
            catch (error) {
                console.error(`Failed to load ${pkg.name}:`, error);
            }
        }
        return results;
    }
    resolvePackageDir(packagePath) {
        const pkgJsonPath = require.resolve(`${packagePath}/package.json`);
        return path_1.default.dirname(pkgJsonPath);
    }
    loadNodeModule(absolutePath) {
        return require(absolutePath);
    }
    async loadPackageNodes(packageName, packagePath, packageJson) {
        const n8nConfig = packageJson.n8n || {};
        const nodes = [];
        const packageDir = this.resolvePackageDir(packagePath);
        const nodesList = n8nConfig.nodes || [];
        if (Array.isArray(nodesList)) {
            for (const nodePath of nodesList) {
                try {
                    const fullPath = path_1.default.join(packageDir, nodePath);
                    const nodeModule = this.loadNodeModule(fullPath);
                    const nodeNameMatch = nodePath.match(/\/([^\/]+)\.node\.(js|ts)$/);
                    const nodeName = nodeNameMatch ? nodeNameMatch[1] : path_1.default.basename(nodePath, '.node.js');
                    const NodeClass = nodeModule.default || nodeModule[nodeName] || Object.values(nodeModule)[0];
                    if (NodeClass) {
                        nodes.push({ packageName, nodeName, NodeClass });
                        console.log(`  ✓ Loaded ${nodeName} from ${packageName}`);
                    }
                    else {
                        console.warn(`  ⚠ No valid export found for ${nodeName} in ${packageName}`);
                    }
                }
                catch (error) {
                    console.error(`  ✗ Failed to load node from ${packageName}/${nodePath}:`, error.message);
                }
            }
        }
        else {
            for (const [nodeName, nodePath] of Object.entries(nodesList)) {
                try {
                    const fullPath = path_1.default.join(packageDir, nodePath);
                    const nodeModule = this.loadNodeModule(fullPath);
                    const NodeClass = nodeModule.default || nodeModule[nodeName] || Object.values(nodeModule)[0];
                    if (NodeClass) {
                        nodes.push({ packageName, nodeName, NodeClass });
                        console.log(`  ✓ Loaded ${nodeName} from ${packageName}`);
                    }
                    else {
                        console.warn(`  ⚠ No valid export found for ${nodeName} in ${packageName}`);
                    }
                }
                catch (error) {
                    console.error(`  ✗ Failed to load node ${nodeName} from ${packageName}:`, error.message);
                }
            }
        }
        return nodes;
    }
}
exports.N8nNodeLoader = N8nNodeLoader;
//# sourceMappingURL=node-loader.js.map