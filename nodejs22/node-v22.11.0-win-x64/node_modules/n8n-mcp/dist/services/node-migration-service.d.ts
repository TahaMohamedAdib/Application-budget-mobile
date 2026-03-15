import { BreakingChangeDetector } from './breaking-change-detector';
import { NodeVersionService } from './node-version-service';
export interface MigrationResult {
    success: boolean;
    nodeId: string;
    nodeName: string;
    fromVersion: string;
    toVersion: string;
    appliedMigrations: AppliedMigration[];
    remainingIssues: string[];
    confidence: 'HIGH' | 'MEDIUM' | 'LOW';
    updatedNode: any;
}
export interface AppliedMigration {
    propertyName: string;
    action: string;
    oldValue?: any;
    newValue?: any;
    description: string;
}
export declare class NodeMigrationService {
    private versionService;
    private breakingChangeDetector;
    constructor(versionService: NodeVersionService, breakingChangeDetector: BreakingChangeDetector);
    migrateNode(node: any, fromVersion: string, toVersion: string): Promise<MigrationResult>;
    private applyMigration;
    private addProperty;
    private removeProperty;
    private renameProperty;
    private setDefault;
    private resolveDefaultValue;
    private parseVersion;
    validateMigratedNode(node: any, nodeType: string): Promise<{
        valid: boolean;
        errors: string[];
        warnings: string[];
    }>;
    migrateWorkflowNodes(workflow: any, targetVersions: Record<string, string>): Promise<{
        success: boolean;
        results: MigrationResult[];
        overallConfidence: 'HIGH' | 'MEDIUM' | 'LOW';
    }>;
}
//# sourceMappingURL=node-migration-service.d.ts.map