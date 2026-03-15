export interface BreakingChange {
    nodeType: string;
    fromVersion: string;
    toVersion: string;
    propertyName: string;
    changeType: 'added' | 'removed' | 'renamed' | 'type_changed' | 'requirement_changed' | 'default_changed';
    isBreaking: boolean;
    oldValue?: string;
    newValue?: string;
    migrationHint: string;
    autoMigratable: boolean;
    migrationStrategy?: {
        type: 'add_property' | 'remove_property' | 'rename_property' | 'set_default';
        defaultValue?: any;
        sourceProperty?: string;
        targetProperty?: string;
    };
    severity: 'LOW' | 'MEDIUM' | 'HIGH';
}
export declare const BREAKING_CHANGES_REGISTRY: BreakingChange[];
export declare function getBreakingChangesForNode(nodeType: string, fromVersion: string, toVersion: string): BreakingChange[];
export declare function getAllChangesForNode(nodeType: string, fromVersion: string, toVersion: string): BreakingChange[];
export declare function getAutoMigratableChanges(nodeType: string, fromVersion: string, toVersion: string): BreakingChange[];
export declare function hasBreakingChanges(nodeType: string, fromVersion: string, toVersion: string): boolean;
export declare function getMigrationHints(nodeType: string, fromVersion: string, toVersion: string): string[];
export declare function getNodesWithVersionMigrations(): string[];
export declare function getTrackedVersionsForNode(nodeType: string): string[];
//# sourceMappingURL=breaking-changes-registry.d.ts.map