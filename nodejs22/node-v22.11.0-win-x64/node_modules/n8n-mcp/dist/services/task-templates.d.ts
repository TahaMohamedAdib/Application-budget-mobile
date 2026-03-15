export interface TaskTemplate {
    task: string;
    description: string;
    nodeType: string;
    configuration: Record<string, any>;
    userMustProvide: Array<{
        property: string;
        description: string;
        example?: any;
    }>;
    optionalEnhancements?: Array<{
        property: string;
        description: string;
        when?: string;
    }>;
    notes?: string[];
}
export declare class TaskTemplates {
    private static templates;
    static getAllTasks(): string[];
    static getTasksForNode(nodeType: string): string[];
    static getTaskTemplate(task: string): TaskTemplate | undefined;
    static getTemplate(task: string): TaskTemplate | undefined;
    static searchTasks(keyword: string): string[];
    static getTaskCategories(): Record<string, string[]>;
}
//# sourceMappingURL=task-templates.d.ts.map