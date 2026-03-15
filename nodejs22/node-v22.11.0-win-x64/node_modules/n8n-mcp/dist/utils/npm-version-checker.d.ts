export interface VersionCheckResult {
    currentVersion: string;
    latestVersion: string | null;
    isOutdated: boolean;
    updateAvailable: boolean;
    error: string | null;
    checkedAt: Date;
    updateCommand?: string;
}
export declare function checkNpmVersion(forceRefresh?: boolean): Promise<VersionCheckResult>;
export declare function compareVersions(v1: string, v2: string): number;
export declare function clearVersionCheckCache(): void;
export declare function formatVersionMessage(result: VersionCheckResult): string;
//# sourceMappingURL=npm-version-checker.d.ts.map