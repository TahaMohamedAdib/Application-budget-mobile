"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.consoleManager = exports.ConsoleManager = void 0;
class ConsoleManager {
    constructor() {
        this.originalConsole = {
            log: console.log,
            error: console.error,
            warn: console.warn,
            info: console.info,
            debug: console.debug,
            trace: console.trace
        };
        this.isSilenced = false;
    }
    silence() {
        if (this.isSilenced || process.env.MCP_MODE !== 'http') {
            return;
        }
        this.isSilenced = true;
        process.env.MCP_REQUEST_ACTIVE = 'true';
        console.log = () => { };
        console.error = () => { };
        console.warn = () => { };
        console.info = () => { };
        console.debug = () => { };
        console.trace = () => { };
    }
    restore() {
        if (!this.isSilenced) {
            return;
        }
        this.isSilenced = false;
        process.env.MCP_REQUEST_ACTIVE = 'false';
        console.log = this.originalConsole.log;
        console.error = this.originalConsole.error;
        console.warn = this.originalConsole.warn;
        console.info = this.originalConsole.info;
        console.debug = this.originalConsole.debug;
        console.trace = this.originalConsole.trace;
    }
    async wrapOperation(operation) {
        this.silence();
        try {
            const result = operation();
            if (result instanceof Promise) {
                return await result.finally(() => this.restore());
            }
            this.restore();
            return result;
        }
        catch (error) {
            this.restore();
            throw error;
        }
    }
    get isActive() {
        return this.isSilenced;
    }
}
exports.ConsoleManager = ConsoleManager;
exports.consoleManager = new ConsoleManager();
//# sourceMappingURL=console-manager.js.map