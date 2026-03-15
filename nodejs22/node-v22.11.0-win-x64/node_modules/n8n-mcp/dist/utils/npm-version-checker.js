"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkNpmVersion = checkNpmVersion;
exports.compareVersions = compareVersions;
exports.clearVersionCheckCache = clearVersionCheckCache;
exports.formatVersionMessage = formatVersionMessage;
const logger_1 = require("./logger");
let versionCheckCache = null;
let lastCheckTime = 0;
const CACHE_TTL_MS = 1 * 60 * 60 * 1000;
async function checkNpmVersion(forceRefresh = false) {
    const now = Date.now();
    if (!forceRefresh && versionCheckCache && (now - lastCheckTime) < CACHE_TTL_MS) {
        logger_1.logger.debug('Returning cached npm version check result');
        return versionCheckCache;
    }
    const packageJson = require('../../package.json');
    const currentVersion = packageJson.version;
    try {
        const response = await fetch('https://registry.npmjs.org/n8n-mcp/latest', {
            headers: {
                'Accept': 'application/json',
            },
            signal: AbortSignal.timeout(5000)
        });
        if (!response.ok) {
            logger_1.logger.warn('Failed to fetch npm version info', {
                status: response.status,
                statusText: response.statusText
            });
            const result = {
                currentVersion,
                latestVersion: null,
                isOutdated: false,
                updateAvailable: false,
                error: `npm registry returned ${response.status}`,
                checkedAt: new Date()
            };
            versionCheckCache = result;
            lastCheckTime = now;
            return result;
        }
        let data;
        try {
            data = await response.json();
        }
        catch (error) {
            throw new Error('Failed to parse npm registry response as JSON');
        }
        if (!data || typeof data !== 'object' || !('version' in data)) {
            throw new Error('Invalid response format from npm registry');
        }
        const registryData = data;
        const latestVersion = registryData.version;
        if (!latestVersion || !/^\d+\.\d+\.\d+/.test(latestVersion)) {
            throw new Error(`Invalid version format from npm registry: ${latestVersion}`);
        }
        const isOutdated = compareVersions(currentVersion, latestVersion) < 0;
        const result = {
            currentVersion,
            latestVersion,
            isOutdated,
            updateAvailable: isOutdated,
            error: null,
            checkedAt: new Date(),
            updateCommand: isOutdated ? `npm install -g n8n-mcp@${latestVersion}` : undefined
        };
        versionCheckCache = result;
        lastCheckTime = now;
        logger_1.logger.debug('npm version check completed', {
            current: currentVersion,
            latest: latestVersion,
            outdated: isOutdated
        });
        return result;
    }
    catch (error) {
        logger_1.logger.warn('Error checking npm version', {
            error: error instanceof Error ? error.message : String(error)
        });
        const result = {
            currentVersion,
            latestVersion: null,
            isOutdated: false,
            updateAvailable: false,
            error: error instanceof Error ? error.message : 'Unknown error',
            checkedAt: new Date()
        };
        versionCheckCache = result;
        lastCheckTime = now;
        return result;
    }
}
function compareVersions(v1, v2) {
    const clean1 = v1.replace(/^v/, '');
    const clean2 = v2.replace(/^v/, '');
    const parts1 = clean1.split('.').map(n => parseInt(n, 10) || 0);
    const parts2 = clean2.split('.').map(n => parseInt(n, 10) || 0);
    for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
        const p1 = parts1[i] || 0;
        const p2 = parts2[i] || 0;
        if (p1 < p2)
            return -1;
        if (p1 > p2)
            return 1;
    }
    return 0;
}
function clearVersionCheckCache() {
    versionCheckCache = null;
    lastCheckTime = 0;
}
function formatVersionMessage(result) {
    if (result.error) {
        return `Version check failed: ${result.error}. Current version: ${result.currentVersion}`;
    }
    if (!result.latestVersion) {
        return `Current version: ${result.currentVersion} (latest version unknown)`;
    }
    if (result.isOutdated) {
        return `⚠️ Update available! Current: ${result.currentVersion} → Latest: ${result.latestVersion}`;
    }
    return `✓ You're up to date! Current version: ${result.currentVersion}`;
}
//# sourceMappingURL=npm-version-checker.js.map