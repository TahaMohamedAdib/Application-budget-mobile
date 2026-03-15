export declare class ConsoleManager {
    private originalConsole;
    private isSilenced;
    silence(): void;
    restore(): void;
    wrapOperation<T>(operation: () => T | Promise<T>): Promise<T>;
    get isActive(): boolean;
}
export declare const consoleManager: ConsoleManager;
//# sourceMappingURL=console-manager.d.ts.map