import { BreakingChangeDetector } from './breaking-change-detector';
import { MigrationResult } from './node-migration-service';
import { NodeVersionService } from './node-version-service';
export interface PostUpdateGuidance {
    nodeId: string;
    nodeName: string;
    nodeType: string;
    oldVersion: string;
    newVersion: string;
    migrationStatus: 'complete' | 'partial' | 'manual_required';
    requiredActions: RequiredAction[];
    deprecatedProperties: DeprecatedProperty[];
    behaviorChanges: BehaviorChange[];
    migrationSteps: string[];
    confidence: 'HIGH' | 'MEDIUM' | 'LOW';
    estimatedTime: string;
}
export interface RequiredAction {
    type: 'ADD_PROPERTY' | 'UPDATE_PROPERTY' | 'CONFIGURE_OPTION' | 'REVIEW_CONFIGURATION';
    property: string;
    reason: string;
    suggestedValue?: any;
    currentValue?: any;
    documentation?: string;
    priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
}
export interface DeprecatedProperty {
    property: string;
    status: 'removed' | 'deprecated';
    replacement?: string;
    action: 'remove' | 'replace' | 'ignore';
    impact: 'breaking' | 'warning';
}
export interface BehaviorChange {
    aspect: string;
    oldBehavior: string;
    newBehavior: string;
    impact: 'HIGH' | 'MEDIUM' | 'LOW';
    actionRequired: boolean;
    recommendation: string;
}
export declare class PostUpdateValidator {
    private versionService;
    private breakingChangeDetector;
    constructor(versionService: NodeVersionService, breakingChangeDetector: BreakingChangeDetector);
    generateGuidance(nodeId: string, nodeName: string, nodeType: string, oldVersion: string, newVersion: string, migrationResult: MigrationResult): Promise<PostUpdateGuidance>;
    private determineMigrationStatus;
    private generateRequiredActions;
    private identifyDeprecatedProperties;
    private documentBehaviorChanges;
    private generateMigrationSteps;
    private mapChangeTypeToActionType;
    private mapSeverityToPriority;
    private getPropertyDocumentation;
    private calculateConfidence;
    private estimateTime;
    generateSummary(guidance: PostUpdateGuidance): string;
}
//# sourceMappingURL=post-update-validator.d.ts.map