import { NodeRepository } from '../database/node-repository';
import { BreakingChangeDetector } from './breaking-change-detector';
export interface NodeVersion {
    nodeType: string;
    version: string;
    packageName: string;
    displayName: string;
    isCurrentMax: boolean;
    minimumN8nVersion?: string;
    breakingChanges: any[];
    deprecatedProperties: string[];
    addedProperties: string[];
    releasedAt?: Date;
}
export interface VersionComparison {
    nodeType: string;
    currentVersion: string;
    latestVersion: string;
    isOutdated: boolean;
    versionGap: number;
    hasBreakingChanges: boolean;
    recommendUpgrade: boolean;
    confidence: 'HIGH' | 'MEDIUM' | 'LOW';
    reason: string;
}
export interface UpgradePath {
    nodeType: string;
    fromVersion: string;
    toVersion: string;
    direct: boolean;
    intermediateVersions: string[];
    totalBreakingChanges: number;
    autoMigratableChanges: number;
    manualRequiredChanges: number;
    estimatedEffort: 'LOW' | 'MEDIUM' | 'HIGH';
    steps: UpgradeStep[];
}
export interface UpgradeStep {
    fromVersion: string;
    toVersion: string;
    breakingChanges: number;
    migrationHints: string[];
}
export declare class NodeVersionService {
    private nodeRepository;
    private breakingChangeDetector;
    private versionCache;
    private cacheTTL;
    private cacheTimestamps;
    constructor(nodeRepository: NodeRepository, breakingChangeDetector: BreakingChangeDetector);
    getAvailableVersions(nodeType: string): NodeVersion[];
    getLatestVersion(nodeType: string): string | null;
    compareVersions(currentVersion: string, latestVersion: string): number;
    analyzeVersion(nodeType: string, currentVersion: string): VersionComparison;
    private calculateVersionGap;
    suggestUpgradePath(nodeType: string, currentVersion: string): Promise<UpgradePath | null>;
    versionExists(nodeType: string, version: string): boolean;
    getVersionMetadata(nodeType: string, version: string): NodeVersion | null;
    clearCache(nodeType?: string): void;
    private getCachedVersions;
    private cacheVersions;
}
//# sourceMappingURL=node-version-service.d.ts.map