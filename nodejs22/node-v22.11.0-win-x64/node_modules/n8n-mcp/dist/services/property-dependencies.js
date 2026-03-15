"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PropertyDependencies = void 0;
class PropertyDependencies {
    static analyze(properties) {
        const dependencies = [];
        const dependencyGraph = {};
        const suggestions = [];
        for (const prop of properties) {
            if (prop.displayOptions?.show || prop.displayOptions?.hide) {
                const dependency = this.extractDependency(prop, properties);
                dependencies.push(dependency);
                for (const condition of dependency.dependsOn) {
                    if (!dependencyGraph[condition.property]) {
                        dependencyGraph[condition.property] = [];
                    }
                    dependencyGraph[condition.property].push(prop.name);
                }
            }
        }
        for (const dep of dependencies) {
            dep.enablesProperties = dependencyGraph[dep.property] || [];
        }
        this.generateSuggestions(dependencies, suggestions);
        return {
            totalProperties: properties.length,
            propertiesWithDependencies: dependencies.length,
            dependencies,
            dependencyGraph,
            suggestions
        };
    }
    static extractDependency(prop, allProperties) {
        const dependency = {
            property: prop.name,
            displayName: prop.displayName || prop.name,
            dependsOn: [],
            showWhen: prop.displayOptions?.show,
            hideWhen: prop.displayOptions?.hide,
            notes: []
        };
        if (prop.displayOptions?.show) {
            for (const [key, values] of Object.entries(prop.displayOptions.show)) {
                const valuesArray = Array.isArray(values) ? values : [values];
                dependency.dependsOn.push({
                    property: key,
                    values: valuesArray,
                    condition: 'equals',
                    description: this.generateConditionDescription(key, valuesArray, 'show', allProperties)
                });
            }
        }
        if (prop.displayOptions?.hide) {
            for (const [key, values] of Object.entries(prop.displayOptions.hide)) {
                const valuesArray = Array.isArray(values) ? values : [values];
                dependency.dependsOn.push({
                    property: key,
                    values: valuesArray,
                    condition: 'not_equals',
                    description: this.generateConditionDescription(key, valuesArray, 'hide', allProperties)
                });
            }
        }
        if (prop.type === 'collection' || prop.type === 'fixedCollection') {
            dependency.notes?.push('This property contains nested properties that may have their own dependencies');
        }
        if (dependency.dependsOn.length > 1) {
            dependency.notes?.push('Multiple conditions must be met for this property to be visible');
        }
        return dependency;
    }
    static generateConditionDescription(property, values, type, allProperties) {
        const prop = allProperties.find(p => p.name === property);
        const propName = prop?.displayName || property;
        if (type === 'show') {
            if (values.length === 1) {
                return `Visible when ${propName} is set to "${values[0]}"`;
            }
            else {
                return `Visible when ${propName} is one of: ${values.map(v => `"${v}"`).join(', ')}`;
            }
        }
        else {
            if (values.length === 1) {
                return `Hidden when ${propName} is set to "${values[0]}"`;
            }
            else {
                return `Hidden when ${propName} is one of: ${values.map(v => `"${v}"`).join(', ')}`;
            }
        }
    }
    static generateSuggestions(dependencies, suggestions) {
        const controllers = new Map();
        for (const dep of dependencies) {
            for (const condition of dep.dependsOn) {
                controllers.set(condition.property, (controllers.get(condition.property) || 0) + 1);
            }
        }
        const sortedControllers = Array.from(controllers.entries())
            .sort((a, b) => b[1] - a[1])
            .slice(0, 3);
        if (sortedControllers.length > 0) {
            suggestions.push(`Key properties to configure first: ${sortedControllers.map(([prop]) => prop).join(', ')}`);
        }
        const complexDeps = dependencies.filter(d => d.dependsOn.length > 1);
        if (complexDeps.length > 0) {
            suggestions.push(`${complexDeps.length} properties have multiple dependencies - check their conditions carefully`);
        }
        for (const dep of dependencies) {
            for (const condition of dep.dependsOn) {
                const targetDep = dependencies.find(d => d.property === condition.property);
                if (targetDep?.dependsOn.some(c => c.property === dep.property)) {
                    suggestions.push(`Circular dependency detected between ${dep.property} and ${condition.property}`);
                }
            }
        }
    }
    static getVisibilityImpact(properties, config) {
        const visible = [];
        const hidden = [];
        const reasons = {};
        for (const prop of properties) {
            const { isVisible, reason } = this.checkVisibility(prop, config);
            if (isVisible) {
                visible.push(prop.name);
            }
            else {
                hidden.push(prop.name);
            }
            if (reason) {
                reasons[prop.name] = reason;
            }
        }
        return { visible, hidden, reasons };
    }
    static checkVisibility(prop, config) {
        if (!prop.displayOptions) {
            return { isVisible: true };
        }
        if (prop.displayOptions.show) {
            for (const [key, values] of Object.entries(prop.displayOptions.show)) {
                const configValue = config[key];
                const expectedValues = Array.isArray(values) ? values : [values];
                if (!expectedValues.includes(configValue)) {
                    return {
                        isVisible: false,
                        reason: `Hidden because ${key} is "${configValue}" (needs to be ${expectedValues.join(' or ')})`
                    };
                }
            }
        }
        if (prop.displayOptions.hide) {
            for (const [key, values] of Object.entries(prop.displayOptions.hide)) {
                const configValue = config[key];
                const expectedValues = Array.isArray(values) ? values : [values];
                if (expectedValues.includes(configValue)) {
                    return {
                        isVisible: false,
                        reason: `Hidden because ${key} is "${configValue}"`
                    };
                }
            }
        }
        return { isVisible: true };
    }
}
exports.PropertyDependencies = PropertyDependencies;
//# sourceMappingURL=property-dependencies.js.map