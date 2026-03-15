"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ResourceNotFoundError = exports.ToolNotFoundError = exports.ValidationError = exports.AuthenticationError = exports.N8NConnectionError = exports.MCPError = void 0;
exports.handleError = handleError;
exports.withErrorHandling = withErrorHandling;
const logger_1 = require("./logger");
class MCPError extends Error {
    constructor(message, code, statusCode, data) {
        super(message);
        this.name = 'MCPError';
        this.code = code;
        this.statusCode = statusCode;
        this.data = data;
    }
}
exports.MCPError = MCPError;
class N8NConnectionError extends MCPError {
    constructor(message, data) {
        super(message, 'N8N_CONNECTION_ERROR', 503, data);
        this.name = 'N8NConnectionError';
    }
}
exports.N8NConnectionError = N8NConnectionError;
class AuthenticationError extends MCPError {
    constructor(message = 'Authentication failed') {
        super(message, 'AUTH_ERROR', 401);
        this.name = 'AuthenticationError';
    }
}
exports.AuthenticationError = AuthenticationError;
class ValidationError extends MCPError {
    constructor(message, data) {
        super(message, 'VALIDATION_ERROR', 400, data);
        this.name = 'ValidationError';
    }
}
exports.ValidationError = ValidationError;
class ToolNotFoundError extends MCPError {
    constructor(toolName) {
        super(`Tool '${toolName}' not found`, 'TOOL_NOT_FOUND', 404);
        this.name = 'ToolNotFoundError';
    }
}
exports.ToolNotFoundError = ToolNotFoundError;
class ResourceNotFoundError extends MCPError {
    constructor(resourceUri) {
        super(`Resource '${resourceUri}' not found`, 'RESOURCE_NOT_FOUND', 404);
        this.name = 'ResourceNotFoundError';
    }
}
exports.ResourceNotFoundError = ResourceNotFoundError;
function handleError(error) {
    if (error instanceof MCPError) {
        return error;
    }
    if (error.response) {
        const status = error.response.status;
        const message = error.response.data?.message || error.message;
        if (status === 401) {
            return new AuthenticationError(message);
        }
        else if (status === 404) {
            return new MCPError(message, 'NOT_FOUND', 404);
        }
        else if (status >= 500) {
            return new N8NConnectionError(message);
        }
        return new MCPError(message, 'API_ERROR', status);
    }
    if (error.code === 'ECONNREFUSED') {
        return new N8NConnectionError('Cannot connect to n8n API');
    }
    return new MCPError(error.message || 'An unexpected error occurred', 'UNKNOWN_ERROR', 500);
}
async function withErrorHandling(operation, context) {
    try {
        return await operation();
    }
    catch (error) {
        logger_1.logger.error(`Error in ${context}:`, error);
        throw handleError(error);
    }
}
//# sourceMappingURL=error-handler.js.map