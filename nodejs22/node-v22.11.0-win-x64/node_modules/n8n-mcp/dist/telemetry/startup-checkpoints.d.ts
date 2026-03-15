export declare const STARTUP_CHECKPOINTS: {
    readonly PROCESS_STARTED: "process_started";
    readonly DATABASE_CONNECTING: "database_connecting";
    readonly DATABASE_CONNECTED: "database_connected";
    readonly N8N_API_CHECKING: "n8n_api_checking";
    readonly N8N_API_READY: "n8n_api_ready";
    readonly TELEMETRY_INITIALIZING: "telemetry_initializing";
    readonly TELEMETRY_READY: "telemetry_ready";
    readonly MCP_HANDSHAKE_STARTING: "mcp_handshake_starting";
    readonly MCP_HANDSHAKE_COMPLETE: "mcp_handshake_complete";
    readonly SERVER_READY: "server_ready";
};
export type StartupCheckpoint = typeof STARTUP_CHECKPOINTS[keyof typeof STARTUP_CHECKPOINTS];
export interface CheckpointData {
    name: StartupCheckpoint;
    timestamp: number;
    success: boolean;
    error?: string;
}
export declare function getAllCheckpoints(): StartupCheckpoint[];
export declare function findFailedCheckpoint(passedCheckpoints: string[]): StartupCheckpoint;
export declare function isValidCheckpoint(checkpoint: string): checkpoint is StartupCheckpoint;
export declare function getCheckpointDescription(checkpoint: StartupCheckpoint): string;
export declare function getNextCheckpoint(current: StartupCheckpoint): StartupCheckpoint | null;
export declare function getCompletionPercentage(passedCheckpoints: string[]): number;
//# sourceMappingURL=startup-checkpoints.d.ts.map