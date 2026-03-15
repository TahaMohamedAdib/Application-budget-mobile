export interface SessionState {
    sessionId: string;
    metadata: {
        createdAt: string;
        lastAccess: string;
    };
    context: {
        n8nApiUrl: string;
        n8nApiKey: string;
        instanceId?: string;
        sessionId?: string;
        metadata?: Record<string, any>;
    };
}
//# sourceMappingURL=session-state.d.ts.map