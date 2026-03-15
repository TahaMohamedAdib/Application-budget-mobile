"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.STARTUP_CHECKPOINTS = void 0;
exports.getAllCheckpoints = getAllCheckpoints;
exports.findFailedCheckpoint = findFailedCheckpoint;
exports.isValidCheckpoint = isValidCheckpoint;
exports.getCheckpointDescription = getCheckpointDescription;
exports.getNextCheckpoint = getNextCheckpoint;
exports.getCompletionPercentage = getCompletionPercentage;
exports.STARTUP_CHECKPOINTS = {
    PROCESS_STARTED: 'process_started',
    DATABASE_CONNECTING: 'database_connecting',
    DATABASE_CONNECTED: 'database_connected',
    N8N_API_CHECKING: 'n8n_api_checking',
    N8N_API_READY: 'n8n_api_ready',
    TELEMETRY_INITIALIZING: 'telemetry_initializing',
    TELEMETRY_READY: 'telemetry_ready',
    MCP_HANDSHAKE_STARTING: 'mcp_handshake_starting',
    MCP_HANDSHAKE_COMPLETE: 'mcp_handshake_complete',
    SERVER_READY: 'server_ready',
};
function getAllCheckpoints() {
    return Object.values(exports.STARTUP_CHECKPOINTS);
}
function findFailedCheckpoint(passedCheckpoints) {
    const allCheckpoints = getAllCheckpoints();
    for (const checkpoint of allCheckpoints) {
        if (!passedCheckpoints.includes(checkpoint)) {
            return checkpoint;
        }
    }
    return exports.STARTUP_CHECKPOINTS.SERVER_READY;
}
function isValidCheckpoint(checkpoint) {
    return getAllCheckpoints().includes(checkpoint);
}
function getCheckpointDescription(checkpoint) {
    const descriptions = {
        [exports.STARTUP_CHECKPOINTS.PROCESS_STARTED]: 'Process initialization started',
        [exports.STARTUP_CHECKPOINTS.DATABASE_CONNECTING]: 'Connecting to database',
        [exports.STARTUP_CHECKPOINTS.DATABASE_CONNECTED]: 'Database connection established',
        [exports.STARTUP_CHECKPOINTS.N8N_API_CHECKING]: 'Checking n8n API configuration',
        [exports.STARTUP_CHECKPOINTS.N8N_API_READY]: 'n8n API ready',
        [exports.STARTUP_CHECKPOINTS.TELEMETRY_INITIALIZING]: 'Initializing telemetry system',
        [exports.STARTUP_CHECKPOINTS.TELEMETRY_READY]: 'Telemetry system ready',
        [exports.STARTUP_CHECKPOINTS.MCP_HANDSHAKE_STARTING]: 'Starting MCP protocol handshake',
        [exports.STARTUP_CHECKPOINTS.MCP_HANDSHAKE_COMPLETE]: 'MCP handshake completed',
        [exports.STARTUP_CHECKPOINTS.SERVER_READY]: 'Server fully initialized and ready',
    };
    return descriptions[checkpoint] || 'Unknown checkpoint';
}
function getNextCheckpoint(current) {
    const allCheckpoints = getAllCheckpoints();
    const currentIndex = allCheckpoints.indexOf(current);
    if (currentIndex === -1 || currentIndex === allCheckpoints.length - 1) {
        return null;
    }
    return allCheckpoints[currentIndex + 1];
}
function getCompletionPercentage(passedCheckpoints) {
    const totalCheckpoints = getAllCheckpoints().length;
    const passedCount = passedCheckpoints.length;
    return Math.round((passedCount / totalCheckpoints) * 100);
}
//# sourceMappingURL=startup-checkpoints.js.map