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
exports.NodeSourceExtractor = void 0;
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
const logger_1 = require("./logger");
class NodeSourceExtractor {
    constructor() {
        this.n8nBasePaths = [
            '/usr/local/lib/node_modules/n8n/node_modules',
            '/app/node_modules',
            '/home/node/.n8n/custom/nodes',
            './node_modules',
            '/var/lib/docker/volumes/n8n-mcp_n8n_modules/_data',
            '/n8n-modules',
            process.env.N8N_CUSTOM_EXTENSIONS || '',
            path.join(process.cwd(), 'node_modules'),
        ].filter(Boolean);
    }
    async extractNodeSource(nodeType) {
        logger_1.logger.info(`Extracting source code for node: ${nodeType}`);
        const { packageName, nodeName } = this.parseNodeType(nodeType);
        for (const basePath of this.n8nBasePaths) {
            try {
                const nodeInfo = await this.searchNodeInPath(basePath, packageName, nodeName);
                if (nodeInfo) {
                    logger_1.logger.info(`Found node source at: ${nodeInfo.location}`);
                    return nodeInfo;
                }
            }
            catch (error) {
                logger_1.logger.debug(`Failed to search in ${basePath}: ${error}`);
            }
        }
        throw new Error(`Node source code not found for: ${nodeType}`);
    }
    parseNodeType(nodeType) {
        if (nodeType.includes('.')) {
            const [pkg, node] = nodeType.split('.');
            return { packageName: pkg, nodeName: node };
        }
        return { packageName: 'n8n-nodes-base', nodeName: nodeType };
    }
    async searchNodeInPath(basePath, packageName, nodeName) {
        try {
            const nodeNameVariants = [
                nodeName,
                nodeName.charAt(0).toUpperCase() + nodeName.slice(1),
                nodeName.toLowerCase(),
                nodeName.toUpperCase(),
            ];
            for (const nameVariant of nodeNameVariants) {
                const standardPatterns = [
                    `${packageName}/dist/nodes/${nameVariant}/${nameVariant}.node.js`,
                    `${packageName}/dist/nodes/${nameVariant}.node.js`,
                    `${packageName}/nodes/${nameVariant}/${nameVariant}.node.js`,
                    `${packageName}/nodes/${nameVariant}.node.js`,
                    `${nameVariant}/${nameVariant}.node.js`,
                    `${nameVariant}.node.js`,
                ];
                const nestedPatterns = [
                    `${packageName}/dist/nodes/*/${nameVariant}/${nameVariant}.node.js`,
                    `${packageName}/dist/nodes/**/${nameVariant}/${nameVariant}.node.js`,
                    `${packageName}/nodes/*/${nameVariant}/${nameVariant}.node.js`,
                    `${packageName}/nodes/**/${nameVariant}/${nameVariant}.node.js`,
                ];
                for (const pattern of standardPatterns) {
                    const fullPath = path.join(basePath, pattern);
                    const result = await this.tryLoadNodeFile(fullPath, packageName, nodeName, basePath);
                    if (result)
                        return result;
                }
                for (const pattern of nestedPatterns) {
                    const result = await this.searchWithGlobPattern(basePath, pattern, packageName, nodeName);
                    if (result)
                        return result;
                }
            }
            if (basePath.includes('node_modules')) {
                const pnpmPath = path.join(basePath, '.pnpm');
                try {
                    await fs.access(pnpmPath);
                    const result = await this.searchInPnpm(pnpmPath, packageName, nodeName);
                    if (result)
                        return result;
                }
                catch {
                }
            }
        }
        catch (error) {
            logger_1.logger.debug(`Error searching in path ${basePath}: ${error}`);
        }
        return null;
    }
    async searchInPnpm(pnpmPath, packageName, nodeName) {
        try {
            const entries = await fs.readdir(pnpmPath);
            const packageEntries = entries.filter(entry => entry.includes(packageName.replace('/', '+')) ||
                entry.includes(packageName));
            for (const entry of packageEntries) {
                const entryPath = path.join(pnpmPath, entry, 'node_modules', packageName);
                const patterns = [
                    `dist/nodes/${nodeName}/${nodeName}.node.js`,
                    `dist/nodes/${nodeName}.node.js`,
                    `dist/nodes/*/${nodeName}/${nodeName}.node.js`,
                    `dist/nodes/**/${nodeName}/${nodeName}.node.js`,
                ];
                for (const pattern of patterns) {
                    if (pattern.includes('*')) {
                        const result = await this.searchWithGlobPattern(entryPath, pattern, packageName, nodeName);
                        if (result)
                            return result;
                    }
                    else {
                        const fullPath = path.join(entryPath, pattern);
                        const result = await this.tryLoadNodeFile(fullPath, packageName, nodeName, entryPath);
                        if (result)
                            return result;
                    }
                }
            }
        }
        catch (error) {
            logger_1.logger.debug(`Error searching in pnpm directory: ${error}`);
        }
        return null;
    }
    async searchWithGlobPattern(basePath, pattern, packageName, nodeName) {
        const parts = pattern.split('/');
        const targetFile = `${nodeName}.node.js`;
        async function searchDir(currentPath, remainingParts) {
            if (remainingParts.length === 0)
                return null;
            const part = remainingParts[0];
            const isLastPart = remainingParts.length === 1;
            try {
                if (isLastPart && part === targetFile) {
                    const fullPath = path.join(currentPath, part);
                    await fs.access(fullPath);
                    return fullPath;
                }
                const entries = await fs.readdir(currentPath, { withFileTypes: true });
                for (const entry of entries) {
                    if (!entry.isDirectory() && !isLastPart)
                        continue;
                    if (part === '*' || part === '**') {
                        if (entry.isDirectory()) {
                            const result = await searchDir(path.join(currentPath, entry.name), part === '**' ? remainingParts : remainingParts.slice(1));
                            if (result)
                                return result;
                        }
                    }
                    else if (entry.name === part || (isLastPart && entry.name === targetFile)) {
                        if (isLastPart && entry.isFile()) {
                            return path.join(currentPath, entry.name);
                        }
                        else if (!isLastPart && entry.isDirectory()) {
                            const result = await searchDir(path.join(currentPath, entry.name), remainingParts.slice(1));
                            if (result)
                                return result;
                        }
                    }
                }
            }
            catch {
            }
            return null;
        }
        const foundPath = await searchDir(basePath, parts);
        if (foundPath) {
            return this.tryLoadNodeFile(foundPath, packageName, nodeName, basePath);
        }
        return null;
    }
    async tryLoadNodeFile(fullPath, packageName, nodeName, packageBasePath) {
        try {
            const sourceCode = await fs.readFile(fullPath, 'utf-8');
            let credentialCode;
            const credentialPath = fullPath.replace('.node.js', '.credentials.js');
            try {
                credentialCode = await fs.readFile(credentialPath, 'utf-8');
            }
            catch {
                const possibleCredentialPaths = [
                    path.join(packageBasePath, packageName, 'dist/credentials', `${nodeName}Api.credentials.js`),
                    path.join(packageBasePath, packageName, 'dist/credentials', `${nodeName}OAuth2Api.credentials.js`),
                    path.join(packageBasePath, packageName, 'credentials', `${nodeName}Api.credentials.js`),
                    path.join(packageBasePath, packageName, 'credentials', `${nodeName}OAuth2Api.credentials.js`),
                    path.join(packageBasePath, 'dist/credentials', `${nodeName}Api.credentials.js`),
                    path.join(packageBasePath, 'dist/credentials', `${nodeName}OAuth2Api.credentials.js`),
                    path.join(packageBasePath, 'credentials', `${nodeName}Api.credentials.js`),
                    path.join(packageBasePath, 'credentials', `${nodeName}OAuth2Api.credentials.js`),
                    path.join(path.dirname(path.dirname(fullPath)), 'credentials', `${nodeName}Api.credentials.js`),
                    path.join(path.dirname(path.dirname(fullPath)), 'credentials', `${nodeName}OAuth2Api.credentials.js`),
                    path.join(path.dirname(path.dirname(path.dirname(fullPath))), 'credentials', `${nodeName}Api.credentials.js`),
                    path.join(path.dirname(path.dirname(path.dirname(fullPath))), 'credentials', `${nodeName}OAuth2Api.credentials.js`),
                ];
                const allCredentials = [];
                for (const credPath of possibleCredentialPaths) {
                    try {
                        const content = await fs.readFile(credPath, 'utf-8');
                        allCredentials.push(content);
                        logger_1.logger.debug(`Found credential file at: ${credPath}`);
                    }
                    catch {
                    }
                }
                if (allCredentials.length > 0) {
                    credentialCode = allCredentials.join('\n\n// --- Next Credential File ---\n\n');
                }
            }
            let packageInfo;
            const possiblePackageJsonPaths = [
                path.join(packageBasePath, 'package.json'),
                path.join(packageBasePath, packageName, 'package.json'),
                path.join(path.dirname(path.dirname(fullPath)), 'package.json'),
                path.join(path.dirname(path.dirname(path.dirname(fullPath))), 'package.json'),
                path.join(fullPath.split('/dist/')[0], 'package.json'),
                path.join(fullPath.split('/nodes/')[0], 'package.json'),
            ];
            for (const packageJsonPath of possiblePackageJsonPaths) {
                try {
                    const packageJson = await fs.readFile(packageJsonPath, 'utf-8');
                    packageInfo = JSON.parse(packageJson);
                    logger_1.logger.debug(`Found package.json at: ${packageJsonPath}`);
                    break;
                }
                catch {
                }
            }
            return {
                nodeType: `${packageName}.${nodeName}`,
                sourceCode,
                credentialCode,
                packageInfo,
                location: fullPath,
            };
        }
        catch {
            return null;
        }
    }
    async listAvailableNodes(category, search) {
        const nodes = [];
        const seenNodes = new Set();
        for (const basePath of this.n8nBasePaths) {
            try {
                const n8nNodesBasePath = path.join(basePath, 'n8n-nodes-base', 'dist', 'nodes');
                try {
                    await fs.access(n8nNodesBasePath);
                    await this.scanDirectoryForNodes(n8nNodesBasePath, nodes, category, search, seenNodes);
                }
                catch {
                    const altPath = path.join(basePath, 'n8n-nodes-base', 'nodes');
                    try {
                        await fs.access(altPath);
                        await this.scanDirectoryForNodes(altPath, nodes, category, search, seenNodes);
                    }
                    catch {
                        await this.scanDirectoryForNodes(basePath, nodes, category, search, seenNodes);
                    }
                }
            }
            catch (error) {
                logger_1.logger.debug(`Failed to scan ${basePath}: ${error}`);
            }
        }
        return nodes;
    }
    async scanDirectoryForNodes(dirPath, nodes, category, search, seenNodes) {
        try {
            const entries = await fs.readdir(dirPath, { withFileTypes: true });
            for (const entry of entries) {
                if (entry.isFile() && entry.name.endsWith('.node.js')) {
                    try {
                        const fullPath = path.join(dirPath, entry.name);
                        const content = await fs.readFile(fullPath, 'utf-8');
                        const nameMatch = content.match(/displayName:\s*['"`]([^'"`]+)['"`]/);
                        const descriptionMatch = content.match(/description:\s*['"`]([^'"`]+)['"`]/);
                        if (nameMatch) {
                            const nodeName = entry.name.replace('.node.js', '');
                            if (seenNodes && seenNodes.has(nodeName)) {
                                continue;
                            }
                            const nodeInfo = {
                                name: nodeName,
                                displayName: nameMatch[1],
                                description: descriptionMatch ? descriptionMatch[1] : '',
                                location: fullPath,
                            };
                            if (category && !nodeInfo.displayName.toLowerCase().includes(category.toLowerCase())) {
                                continue;
                            }
                            if (search && !nodeInfo.displayName.toLowerCase().includes(search.toLowerCase()) &&
                                !nodeInfo.description.toLowerCase().includes(search.toLowerCase())) {
                                continue;
                            }
                            nodes.push(nodeInfo);
                            if (seenNodes) {
                                seenNodes.add(nodeName);
                            }
                        }
                    }
                    catch {
                    }
                }
                else if (entry.isDirectory()) {
                    if (entry.name === '.pnpm') {
                        await this.scanPnpmDirectory(path.join(dirPath, entry.name), nodes, category, search, seenNodes);
                    }
                    else if (entry.name !== 'node_modules') {
                        await this.scanDirectoryForNodes(path.join(dirPath, entry.name), nodes, category, search, seenNodes);
                    }
                }
            }
        }
        catch (error) {
            logger_1.logger.debug(`Error scanning directory ${dirPath}: ${error}`);
        }
    }
    async scanPnpmDirectory(pnpmPath, nodes, category, search, seenNodes) {
        try {
            const entries = await fs.readdir(pnpmPath);
            for (const entry of entries) {
                const entryPath = path.join(pnpmPath, entry, 'node_modules');
                try {
                    await fs.access(entryPath);
                    await this.scanDirectoryForNodes(entryPath, nodes, category, search, seenNodes);
                }
                catch {
                }
            }
        }
        catch (error) {
            logger_1.logger.debug(`Error scanning pnpm directory ${pnpmPath}: ${error}`);
        }
    }
    async extractAIAgentNode() {
        return this.extractNodeSource('@n8n/n8n-nodes-langchain.Agent');
    }
}
exports.NodeSourceExtractor = NodeSourceExtractor;
//# sourceMappingURL=node-source-extractor.js.map