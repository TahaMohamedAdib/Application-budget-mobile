"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PostUpdateValidator = void 0;
class PostUpdateValidator {
    constructor(versionService, breakingChangeDetector) {
        this.versionService = versionService;
        this.breakingChangeDetector = breakingChangeDetector;
    }
    async generateGuidance(nodeId, nodeName, nodeType, oldVersion, newVersion, migrationResult) {
        const analysis = await this.breakingChangeDetector.analyzeVersionUpgrade(nodeType, oldVersion, newVersion);
        const migrationStatus = this.determineMigrationStatus(migrationResult, analysis.changes);
        const requiredActions = this.generateRequiredActions(migrationResult, analysis.changes, nodeType);
        const deprecatedProperties = this.identifyDeprecatedProperties(analysis.changes);
        const behaviorChanges = this.documentBehaviorChanges(nodeType, oldVersion, newVersion);
        const migrationSteps = this.generateMigrationSteps(requiredActions, deprecatedProperties, behaviorChanges);
        const confidence = this.calculateConfidence(requiredActions, migrationStatus);
        const estimatedTime = this.estimateTime(requiredActions, behaviorChanges);
        return {
            nodeId,
            nodeName,
            nodeType,
            oldVersion,
            newVersion,
            migrationStatus,
            requiredActions,
            deprecatedProperties,
            behaviorChanges,
            migrationSteps,
            confidence,
            estimatedTime
        };
    }
    determineMigrationStatus(migrationResult, changes) {
        if (migrationResult.remainingIssues.length === 0) {
            return 'complete';
        }
        const criticalIssues = changes.filter(c => c.isBreaking && !c.autoMigratable);
        if (criticalIssues.length > 0) {
            return 'manual_required';
        }
        return 'partial';
    }
    generateRequiredActions(migrationResult, changes, nodeType) {
        const actions = [];
        const manualChanges = changes.filter(c => !c.autoMigratable);
        for (const change of manualChanges) {
            actions.push({
                type: this.mapChangeTypeToActionType(change.changeType),
                property: change.propertyName,
                reason: change.migrationHint,
                suggestedValue: change.newValue,
                currentValue: change.oldValue,
                documentation: this.getPropertyDocumentation(nodeType, change.propertyName),
                priority: this.mapSeverityToPriority(change.severity)
            });
        }
        return actions;
    }
    identifyDeprecatedProperties(changes) {
        const deprecated = [];
        for (const change of changes) {
            if (change.changeType === 'removed') {
                deprecated.push({
                    property: change.propertyName,
                    status: 'removed',
                    replacement: change.migrationStrategy?.targetProperty,
                    action: change.autoMigratable ? 'remove' : 'replace',
                    impact: change.isBreaking ? 'breaking' : 'warning'
                });
            }
        }
        return deprecated;
    }
    documentBehaviorChanges(nodeType, oldVersion, newVersion) {
        const changes = [];
        if (nodeType === 'n8n-nodes-base.executeWorkflow') {
            if (this.versionService.compareVersions(oldVersion, '1.1') < 0 &&
                this.versionService.compareVersions(newVersion, '1.1') >= 0) {
                changes.push({
                    aspect: 'Data passing to sub-workflows',
                    oldBehavior: 'Automatic data passing - all data from parent workflow automatically available',
                    newBehavior: 'Explicit field mapping required - must define inputFieldMapping to pass specific fields',
                    impact: 'HIGH',
                    actionRequired: true,
                    recommendation: 'Define inputFieldMapping with specific field mappings between parent and child workflows. Review data dependencies.'
                });
            }
        }
        if (nodeType === 'n8n-nodes-base.webhook') {
            if (this.versionService.compareVersions(oldVersion, '2.1') < 0 &&
                this.versionService.compareVersions(newVersion, '2.1') >= 0) {
                changes.push({
                    aspect: 'Webhook persistence',
                    oldBehavior: 'Webhook URL changes on workflow updates',
                    newBehavior: 'Stable webhook URL via webhookId field',
                    impact: 'MEDIUM',
                    actionRequired: false,
                    recommendation: 'Webhook URLs now remain stable across workflow updates. Update external systems if needed.'
                });
            }
            if (this.versionService.compareVersions(oldVersion, '2.0') < 0 &&
                this.versionService.compareVersions(newVersion, '2.0') >= 0) {
                changes.push({
                    aspect: 'Response handling',
                    oldBehavior: 'Automatic response after webhook trigger',
                    newBehavior: 'Configurable response mode (onReceived vs lastNode)',
                    impact: 'MEDIUM',
                    actionRequired: true,
                    recommendation: 'Review responseMode setting. Use "onReceived" for immediate responses or "lastNode" to wait for workflow completion.'
                });
            }
        }
        return changes;
    }
    generateMigrationSteps(requiredActions, deprecatedProperties, behaviorChanges) {
        const steps = [];
        let stepNumber = 1;
        if (deprecatedProperties.length > 0) {
            steps.push(`Step ${stepNumber++}: Remove deprecated properties`);
            for (const dep of deprecatedProperties) {
                steps.push(`  - Remove "${dep.property}" ${dep.replacement ? `(use "${dep.replacement}" instead)` : ''}`);
            }
        }
        const criticalActions = requiredActions.filter(a => a.priority === 'CRITICAL');
        if (criticalActions.length > 0) {
            steps.push(`Step ${stepNumber++}: Address critical configuration requirements`);
            for (const action of criticalActions) {
                steps.push(`  - ${action.property}: ${action.reason}`);
                if (action.suggestedValue !== undefined) {
                    steps.push(`    Suggested value: ${JSON.stringify(action.suggestedValue)}`);
                }
            }
        }
        const highActions = requiredActions.filter(a => a.priority === 'HIGH');
        if (highActions.length > 0) {
            steps.push(`Step ${stepNumber++}: Configure required properties`);
            for (const action of highActions) {
                steps.push(`  - ${action.property}: ${action.reason}`);
            }
        }
        const actionRequiredChanges = behaviorChanges.filter(c => c.actionRequired);
        if (actionRequiredChanges.length > 0) {
            steps.push(`Step ${stepNumber++}: Adapt to behavior changes`);
            for (const change of actionRequiredChanges) {
                steps.push(`  - ${change.aspect}: ${change.recommendation}`);
            }
        }
        const otherActions = requiredActions.filter(a => a.priority === 'MEDIUM' || a.priority === 'LOW');
        if (otherActions.length > 0) {
            steps.push(`Step ${stepNumber++}: Review optional configurations`);
            for (const action of otherActions) {
                steps.push(`  - ${action.property}: ${action.reason}`);
            }
        }
        steps.push(`Step ${stepNumber}: Test workflow execution`);
        steps.push('  - Validate all node configurations');
        steps.push('  - Run a test execution');
        steps.push('  - Verify expected behavior');
        return steps;
    }
    mapChangeTypeToActionType(changeType) {
        switch (changeType) {
            case 'added':
                return 'ADD_PROPERTY';
            case 'requirement_changed':
            case 'type_changed':
                return 'UPDATE_PROPERTY';
            case 'default_changed':
                return 'CONFIGURE_OPTION';
            default:
                return 'REVIEW_CONFIGURATION';
        }
    }
    mapSeverityToPriority(severity) {
        if (severity === 'HIGH')
            return 'CRITICAL';
        return severity;
    }
    getPropertyDocumentation(nodeType, propertyName) {
        return `See n8n documentation for ${nodeType} - ${propertyName}`;
    }
    calculateConfidence(requiredActions, migrationStatus) {
        if (migrationStatus === 'complete')
            return 'HIGH';
        const criticalActions = requiredActions.filter(a => a.priority === 'CRITICAL');
        if (migrationStatus === 'manual_required' || criticalActions.length > 3) {
            return 'LOW';
        }
        return 'MEDIUM';
    }
    estimateTime(requiredActions, behaviorChanges) {
        const criticalCount = requiredActions.filter(a => a.priority === 'CRITICAL').length;
        const highCount = requiredActions.filter(a => a.priority === 'HIGH').length;
        const behaviorCount = behaviorChanges.filter(c => c.actionRequired).length;
        const totalComplexity = criticalCount * 5 + highCount * 3 + behaviorCount * 2;
        if (totalComplexity === 0)
            return '< 1 minute';
        if (totalComplexity <= 5)
            return '2-5 minutes';
        if (totalComplexity <= 10)
            return '5-10 minutes';
        if (totalComplexity <= 20)
            return '10-20 minutes';
        return '20+ minutes';
    }
    generateSummary(guidance) {
        const lines = [];
        lines.push(`Node "${guidance.nodeName}" upgraded from v${guidance.oldVersion} to v${guidance.newVersion}`);
        lines.push(`Status: ${guidance.migrationStatus.toUpperCase()}`);
        lines.push(`Confidence: ${guidance.confidence}`);
        lines.push(`Estimated time: ${guidance.estimatedTime}`);
        if (guidance.requiredActions.length > 0) {
            lines.push(`\nRequired actions: ${guidance.requiredActions.length}`);
            for (const action of guidance.requiredActions.slice(0, 3)) {
                lines.push(`  - [${action.priority}] ${action.property}: ${action.reason}`);
            }
            if (guidance.requiredActions.length > 3) {
                lines.push(`  ... and ${guidance.requiredActions.length - 3} more`);
            }
        }
        if (guidance.behaviorChanges.length > 0) {
            lines.push(`\nBehavior changes: ${guidance.behaviorChanges.length}`);
            for (const change of guidance.behaviorChanges) {
                lines.push(`  - ${change.aspect}: ${change.newBehavior}`);
            }
        }
        return lines.join('\n');
    }
}
exports.PostUpdateValidator = PostUpdateValidator;
//# sourceMappingURL=post-update-validator.js.map