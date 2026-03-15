"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BreakingChangeDetector = void 0;
const breaking_changes_registry_1 = require("./breaking-changes-registry");
class BreakingChangeDetector {
    constructor(nodeRepository) {
        this.nodeRepository = nodeRepository;
    }
    async analyzeVersionUpgrade(nodeType, fromVersion, toVersion) {
        const registryChanges = this.getRegistryChanges(nodeType, fromVersion, toVersion);
        const dynamicChanges = this.detectDynamicChanges(nodeType, fromVersion, toVersion);
        const allChanges = this.mergeChanges(registryChanges, dynamicChanges);
        const hasBreakingChanges = allChanges.some(c => c.isBreaking);
        const autoMigratableCount = allChanges.filter(c => c.autoMigratable).length;
        const manualRequiredCount = allChanges.filter(c => !c.autoMigratable).length;
        const overallSeverity = this.calculateOverallSeverity(allChanges);
        const recommendations = this.generateRecommendations(allChanges);
        return {
            nodeType,
            fromVersion,
            toVersion,
            hasBreakingChanges,
            changes: allChanges,
            autoMigratableCount,
            manualRequiredCount,
            overallSeverity,
            recommendations
        };
    }
    getRegistryChanges(nodeType, fromVersion, toVersion) {
        const registryChanges = (0, breaking_changes_registry_1.getAllChangesForNode)(nodeType, fromVersion, toVersion);
        return registryChanges.map(change => ({
            propertyName: change.propertyName,
            changeType: change.changeType,
            isBreaking: change.isBreaking,
            oldValue: change.oldValue,
            newValue: change.newValue,
            migrationHint: change.migrationHint,
            autoMigratable: change.autoMigratable,
            migrationStrategy: change.migrationStrategy,
            severity: change.severity,
            source: 'registry'
        }));
    }
    detectDynamicChanges(nodeType, fromVersion, toVersion) {
        const oldVersionData = this.nodeRepository.getNodeVersion(nodeType, fromVersion);
        const newVersionData = this.nodeRepository.getNodeVersion(nodeType, toVersion);
        if (!oldVersionData || !newVersionData) {
            return [];
        }
        const changes = [];
        const oldProps = this.flattenProperties(oldVersionData.propertiesSchema || []);
        const newProps = this.flattenProperties(newVersionData.propertiesSchema || []);
        for (const propName of Object.keys(newProps)) {
            if (!oldProps[propName]) {
                const prop = newProps[propName];
                const isRequired = prop.required === true;
                changes.push({
                    propertyName: propName,
                    changeType: 'added',
                    isBreaking: isRequired,
                    newValue: prop.type || 'unknown',
                    migrationHint: isRequired
                        ? `Property "${propName}" is now required in v${toVersion}. Provide a value to prevent validation errors.`
                        : `Property "${propName}" was added in v${toVersion}. Optional parameter, safe to ignore if not needed.`,
                    autoMigratable: !isRequired,
                    migrationStrategy: !isRequired
                        ? {
                            type: 'add_property',
                            defaultValue: prop.default || null
                        }
                        : undefined,
                    severity: isRequired ? 'HIGH' : 'LOW',
                    source: 'dynamic'
                });
            }
        }
        for (const propName of Object.keys(oldProps)) {
            if (!newProps[propName]) {
                changes.push({
                    propertyName: propName,
                    changeType: 'removed',
                    isBreaking: true,
                    oldValue: oldProps[propName].type || 'unknown',
                    migrationHint: `Property "${propName}" was removed in v${toVersion}. Remove this property from your configuration.`,
                    autoMigratable: true,
                    migrationStrategy: {
                        type: 'remove_property'
                    },
                    severity: 'MEDIUM',
                    source: 'dynamic'
                });
            }
        }
        for (const propName of Object.keys(newProps)) {
            if (oldProps[propName]) {
                const oldRequired = oldProps[propName].required === true;
                const newRequired = newProps[propName].required === true;
                if (oldRequired !== newRequired) {
                    changes.push({
                        propertyName: propName,
                        changeType: 'requirement_changed',
                        isBreaking: newRequired && !oldRequired,
                        oldValue: oldRequired ? 'required' : 'optional',
                        newValue: newRequired ? 'required' : 'optional',
                        migrationHint: newRequired
                            ? `Property "${propName}" is now required in v${toVersion}. Ensure a value is provided.`
                            : `Property "${propName}" is now optional in v${toVersion}.`,
                        autoMigratable: false,
                        severity: newRequired ? 'HIGH' : 'LOW',
                        source: 'dynamic'
                    });
                }
            }
        }
        return changes;
    }
    flattenProperties(properties, prefix = '') {
        const flat = {};
        for (const prop of properties) {
            if (!prop.name && !prop.displayName)
                continue;
            const propName = prop.name || prop.displayName;
            const fullPath = prefix ? `${prefix}.${propName}` : propName;
            flat[fullPath] = prop;
            if (prop.options && Array.isArray(prop.options)) {
                Object.assign(flat, this.flattenProperties(prop.options, fullPath));
            }
        }
        return flat;
    }
    mergeChanges(registryChanges, dynamicChanges) {
        const merged = [...registryChanges];
        for (const dynamicChange of dynamicChanges) {
            const existsInRegistry = registryChanges.some(rc => rc.propertyName === dynamicChange.propertyName &&
                rc.changeType === dynamicChange.changeType);
            if (!existsInRegistry) {
                merged.push(dynamicChange);
            }
        }
        const severityOrder = { HIGH: 0, MEDIUM: 1, LOW: 2 };
        merged.sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity]);
        return merged;
    }
    calculateOverallSeverity(changes) {
        if (changes.some(c => c.severity === 'HIGH'))
            return 'HIGH';
        if (changes.some(c => c.severity === 'MEDIUM'))
            return 'MEDIUM';
        return 'LOW';
    }
    generateRecommendations(changes) {
        const recommendations = [];
        const breakingChanges = changes.filter(c => c.isBreaking);
        const autoMigratable = changes.filter(c => c.autoMigratable);
        const manualRequired = changes.filter(c => !c.autoMigratable);
        if (breakingChanges.length === 0) {
            recommendations.push('✓ No breaking changes detected. This upgrade should be safe.');
        }
        else {
            recommendations.push(`⚠ ${breakingChanges.length} breaking change(s) detected. Review carefully before applying.`);
        }
        if (autoMigratable.length > 0) {
            recommendations.push(`✓ ${autoMigratable.length} change(s) can be automatically migrated.`);
        }
        if (manualRequired.length > 0) {
            recommendations.push(`✋ ${manualRequired.length} change(s) require manual intervention.`);
            for (const change of manualRequired) {
                recommendations.push(`  - ${change.propertyName}: ${change.migrationHint}`);
            }
        }
        return recommendations;
    }
    hasBreakingChanges(nodeType, fromVersion, toVersion) {
        const registryChanges = (0, breaking_changes_registry_1.getBreakingChangesForNode)(nodeType, fromVersion, toVersion);
        return registryChanges.length > 0;
    }
    getChangedProperties(nodeType, fromVersion, toVersion) {
        const registryChanges = (0, breaking_changes_registry_1.getAllChangesForNode)(nodeType, fromVersion, toVersion);
        return registryChanges.map(c => c.propertyName);
    }
}
exports.BreakingChangeDetector = BreakingChangeDetector;
//# sourceMappingURL=breaking-change-detector.js.map