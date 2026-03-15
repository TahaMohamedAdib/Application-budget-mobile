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
const dotenv = __importStar(require("dotenv"));
const node_documentation_service_1 = require("../services/node-documentation-service");
const node_source_extractor_1 = require("../utils/node-source-extractor");
const logger_1 = require("../utils/logger");
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
dotenv.config();
async function extractNodesFromDocker() {
    logger_1.logger.info('🐳 Starting Docker-based node extraction...');
    const dockerVolumePaths = [
        process.env.N8N_MODULES_PATH || '/n8n-modules',
        process.env.N8N_CUSTOM_PATH || '/n8n-custom',
    ];
    logger_1.logger.info(`Docker volume paths: ${dockerVolumePaths.join(', ')}`);
    for (const volumePath of dockerVolumePaths) {
        try {
            await fs.access(volumePath);
            logger_1.logger.info(`✅ Volume mounted: ${volumePath}`);
            const entries = await fs.readdir(volumePath);
            logger_1.logger.info(`Contents of ${volumePath}: ${entries.slice(0, 10).join(', ')}${entries.length > 10 ? '...' : ''}`);
        }
        catch (error) {
            logger_1.logger.warn(`❌ Volume not accessible: ${volumePath}`);
        }
    }
    const docService = new node_documentation_service_1.NodeDocumentationService();
    const extractor = new node_source_extractor_1.NodeSourceExtractor();
    extractor.n8nBasePaths.unshift(...dockerVolumePaths);
    logger_1.logger.info('🧹 Clearing existing nodes...');
    const db = docService.db;
    db.prepare('DELETE FROM nodes').run();
    logger_1.logger.info('🔍 Searching for n8n nodes in Docker volumes...');
    const n8nPackages = [
        'n8n-nodes-base',
        '@n8n/n8n-nodes-langchain',
        'n8n-nodes-extras',
    ];
    let totalExtracted = 0;
    let ifNodeVersion = null;
    for (const packageName of n8nPackages) {
        logger_1.logger.info(`\n📦 Processing package: ${packageName}`);
        try {
            let packagePath = null;
            for (const volumePath of dockerVolumePaths) {
                const possiblePaths = [
                    path.join(volumePath, packageName),
                    path.join(volumePath, '.pnpm', `${packageName}@*`, 'node_modules', packageName),
                ];
                for (const testPath of possiblePaths) {
                    try {
                        if (testPath.includes('*')) {
                            const baseDir = path.dirname(testPath.split('*')[0]);
                            const entries = await fs.readdir(baseDir);
                            for (const entry of entries) {
                                if (entry.includes(packageName.replace('/', '+'))) {
                                    const fullPath = path.join(baseDir, entry, 'node_modules', packageName);
                                    try {
                                        await fs.access(fullPath);
                                        packagePath = fullPath;
                                        break;
                                    }
                                    catch { }
                                }
                            }
                        }
                        else {
                            await fs.access(testPath);
                            packagePath = testPath;
                            break;
                        }
                    }
                    catch { }
                }
                if (packagePath)
                    break;
            }
            if (!packagePath) {
                logger_1.logger.warn(`Package ${packageName} not found in Docker volumes`);
                continue;
            }
            logger_1.logger.info(`Found package at: ${packagePath}`);
            try {
                const packageJsonPath = path.join(packagePath, 'package.json');
                const packageJson = JSON.parse(await fs.readFile(packageJsonPath, 'utf-8'));
                logger_1.logger.info(`Package version: ${packageJson.version}`);
            }
            catch { }
            const nodesPath = path.join(packagePath, 'dist', 'nodes');
            try {
                await fs.access(nodesPath);
                logger_1.logger.info(`Scanning nodes directory: ${nodesPath}`);
                const nodeEntries = await scanForNodes(nodesPath);
                logger_1.logger.info(`Found ${nodeEntries.length} nodes in ${packageName}`);
                for (const nodeEntry of nodeEntries) {
                    try {
                        const nodeName = nodeEntry.name.replace('.node.js', '');
                        const nodeType = `${packageName}.${nodeName}`;
                        logger_1.logger.info(`Extracting: ${nodeType}`);
                        const sourceInfo = await extractor.extractNodeSource(nodeType);
                        if (nodeName === 'If') {
                            const versionMatch = sourceInfo.sourceCode.match(/version:\s*(\d+)/);
                            if (versionMatch) {
                                ifNodeVersion = versionMatch[1];
                                logger_1.logger.info(`📍 Found If node version: ${ifNodeVersion}`);
                            }
                        }
                        await docService.storeNode({
                            nodeType: nodeType,
                            name: nodeName,
                            displayName: nodeName,
                            description: `${nodeName} node from ${packageName}`,
                            sourceCode: sourceInfo.sourceCode,
                            credentialCode: sourceInfo.credentialCode,
                            packageName: packageName,
                            version: ifNodeVersion || '1',
                            hasCredentials: !!sourceInfo.credentialCode,
                            isTrigger: sourceInfo.sourceCode.includes('trigger: true') || nodeName.toLowerCase().includes('trigger'),
                            isWebhook: sourceInfo.sourceCode.includes('webhook: true') || nodeName.toLowerCase().includes('webhook'),
                        });
                        totalExtracted++;
                    }
                    catch (error) {
                        logger_1.logger.error(`Failed to extract ${nodeEntry.name}: ${error}`);
                    }
                }
            }
            catch (error) {
                logger_1.logger.error(`Failed to scan nodes directory: ${error}`);
            }
        }
        catch (error) {
            logger_1.logger.error(`Failed to process package ${packageName}: ${error}`);
        }
    }
    logger_1.logger.info(`\n✅ Extraction complete!`);
    logger_1.logger.info(`📊 Total nodes extracted: ${totalExtracted}`);
    if (ifNodeVersion) {
        logger_1.logger.info(`📍 If node version: ${ifNodeVersion}`);
        if (ifNodeVersion === '2' || ifNodeVersion === '2.2') {
            logger_1.logger.info('✅ Successfully extracted latest If node (v2+)!');
        }
        else {
            logger_1.logger.warn(`⚠️ If node version is ${ifNodeVersion}, expected v2 or higher`);
        }
    }
    await docService.close();
}
async function scanForNodes(dirPath) {
    const nodes = [];
    async function scan(currentPath) {
        try {
            const entries = await fs.readdir(currentPath, { withFileTypes: true });
            for (const entry of entries) {
                const fullPath = path.join(currentPath, entry.name);
                if (entry.isFile() && entry.name.endsWith('.node.js')) {
                    nodes.push({ name: entry.name, path: fullPath });
                }
                else if (entry.isDirectory() && entry.name !== 'node_modules') {
                    await scan(fullPath);
                }
            }
        }
        catch (error) {
            logger_1.logger.debug(`Failed to scan directory ${currentPath}: ${error}`);
        }
    }
    await scan(dirPath);
    return nodes;
}
extractNodesFromDocker().catch(error => {
    logger_1.logger.error('Extraction failed:', error);
    process.exit(1);
});
//# sourceMappingURL=extract-from-docker.js.map