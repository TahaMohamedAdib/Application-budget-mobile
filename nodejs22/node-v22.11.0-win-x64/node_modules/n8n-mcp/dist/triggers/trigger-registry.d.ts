import { N8nApiClient } from '../services/n8n-api-client';
import { InstanceContext } from '../types/instance-context';
import { TriggerType } from './types';
import { BaseTriggerHandler, TriggerHandlerConstructor } from './handlers/base-handler';
export declare class TriggerRegistry {
    private static handlers;
    private static initialized;
    static register(type: TriggerType, HandlerClass: TriggerHandlerConstructor): void;
    static getHandler(type: TriggerType, client: N8nApiClient, context?: InstanceContext): BaseTriggerHandler | undefined;
    static hasHandler(type: TriggerType): boolean;
    static getRegisteredTypes(): TriggerType[];
    static clear(): void;
    static isInitialized(): boolean;
    static markInitialized(): void;
}
export declare function initializeTriggerRegistry(): Promise<void>;
export declare function ensureRegistryInitialized(): Promise<void>;
//# sourceMappingURL=trigger-registry.d.ts.map