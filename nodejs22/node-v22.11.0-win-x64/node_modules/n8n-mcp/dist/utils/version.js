"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PROJECT_VERSION = void 0;
const fs_1 = require("fs");
const path_1 = require("path");
function getProjectVersion() {
    try {
        const packageJsonPath = (0, path_1.join)(__dirname, '../../package.json');
        const packageJson = JSON.parse((0, fs_1.readFileSync)(packageJsonPath, 'utf-8'));
        return packageJson.version || '0.0.0';
    }
    catch (error) {
        console.error('Failed to read version from package.json:', error);
        return '0.0.0';
    }
}
exports.PROJECT_VERSION = getProjectVersion();
//# sourceMappingURL=version.js.map