"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SUPPORTED_VERSIONS = exports.N8N_PROTOCOL_VERSION = exports.STANDARD_PROTOCOL_VERSION = void 0;
exports.isN8nClient = isN8nClient;
exports.negotiateProtocolVersion = negotiateProtocolVersion;
exports.isVersionSupported = isVersionSupported;
exports.getCompatibleVersion = getCompatibleVersion;
exports.logProtocolNegotiation = logProtocolNegotiation;
exports.STANDARD_PROTOCOL_VERSION = '2025-03-26';
exports.N8N_PROTOCOL_VERSION = '2024-11-05';
exports.SUPPORTED_VERSIONS = [
    exports.STANDARD_PROTOCOL_VERSION,
    exports.N8N_PROTOCOL_VERSION,
    '2024-06-25',
];
function isN8nClient(clientInfo, userAgent, headers) {
    if (clientInfo?.name) {
        const clientName = clientInfo.name.toLowerCase();
        if (clientName.includes('n8n') || clientName.includes('langchain')) {
            return true;
        }
    }
    if (userAgent) {
        const ua = userAgent.toLowerCase();
        if (ua.includes('n8n') || ua.includes('langchain')) {
            return true;
        }
    }
    if (headers) {
        const headerValues = Object.values(headers).join(' ').toLowerCase();
        if (headerValues.includes('n8n') || headerValues.includes('langchain')) {
            return true;
        }
        if (headers['x-n8n-version'] || headers['x-langchain-version']) {
            return true;
        }
    }
    if (process.env.N8N_MODE === 'true') {
        return true;
    }
    return false;
}
function negotiateProtocolVersion(clientRequestedVersion, clientInfo, userAgent, headers) {
    const isN8n = isN8nClient(clientInfo, userAgent, headers);
    if (isN8n) {
        return {
            version: exports.N8N_PROTOCOL_VERSION,
            isN8nClient: true,
            reasoning: 'n8n client detected, using n8n-compatible protocol version'
        };
    }
    if (clientRequestedVersion && exports.SUPPORTED_VERSIONS.includes(clientRequestedVersion)) {
        return {
            version: clientRequestedVersion,
            isN8nClient: false,
            reasoning: `Using client-requested version: ${clientRequestedVersion}`
        };
    }
    if (clientRequestedVersion) {
        return {
            version: exports.STANDARD_PROTOCOL_VERSION,
            isN8nClient: false,
            reasoning: `Client requested unsupported version ${clientRequestedVersion}, using standard version`
        };
    }
    return {
        version: exports.STANDARD_PROTOCOL_VERSION,
        isN8nClient: false,
        reasoning: 'No specific client detected, using standard protocol version'
    };
}
function isVersionSupported(version) {
    return exports.SUPPORTED_VERSIONS.includes(version);
}
function getCompatibleVersion(targetVersion) {
    if (!targetVersion) {
        return exports.STANDARD_PROTOCOL_VERSION;
    }
    if (exports.SUPPORTED_VERSIONS.includes(targetVersion)) {
        return targetVersion;
    }
    return exports.STANDARD_PROTOCOL_VERSION;
}
function logProtocolNegotiation(result, logger, context) {
    const logContext = context ? `[${context}] ` : '';
    logger.info(`${logContext}Protocol version negotiated`, {
        version: result.version,
        isN8nClient: result.isN8nClient,
        reasoning: result.reasoning
    });
    if (result.isN8nClient) {
        logger.info(`${logContext}Using n8n-compatible protocol version for better integration`);
    }
}
//# sourceMappingURL=protocol-version.js.map