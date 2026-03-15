export interface TelemetryConfig {
    enabled: boolean;
    userId: string;
    firstRun?: string;
    lastModified?: string;
    version?: string;
}
export declare class TelemetryConfigManager {
    private static instance;
    private readonly configDir;
    private readonly configPath;
    private config;
    private constructor();
    static getInstance(): TelemetryConfigManager;
    private generateUserId;
    private generateDockerStableId;
    private readBootId;
    private generateCombinedFingerprint;
    private isCloudEnvironment;
    loadConfig(): TelemetryConfig;
    private saveConfig;
    isEnabled(): boolean;
    private isDisabledByEnvironment;
    getUserId(): string;
    isFirstRun(): boolean;
    enable(): void;
    disable(): void;
    getStatus(): string;
    private showFirstRunNotice;
    private getPackageVersion;
}
//# sourceMappingURL=config-manager.d.ts.map