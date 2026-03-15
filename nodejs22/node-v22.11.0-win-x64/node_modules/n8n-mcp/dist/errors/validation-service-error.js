"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ValidationServiceError = void 0;
class ValidationServiceError extends Error {
    constructor(message, nodeType, property, cause) {
        super(message);
        this.nodeType = nodeType;
        this.property = property;
        this.cause = cause;
        this.name = 'ValidationServiceError';
        if (Error.captureStackTrace) {
            Error.captureStackTrace(this, ValidationServiceError);
        }
    }
    static jsonParseError(nodeType, cause) {
        return new ValidationServiceError(`Failed to parse JSON data for node ${nodeType}`, nodeType, undefined, cause);
    }
    static nodeNotFound(nodeType) {
        return new ValidationServiceError(`Node type ${nodeType} not found in repository`, nodeType);
    }
    static dataExtractionError(nodeType, dataType, cause) {
        return new ValidationServiceError(`Failed to extract ${dataType} for node ${nodeType}`, nodeType, dataType, cause);
    }
}
exports.ValidationServiceError = ValidationServiceError;
//# sourceMappingURL=validation-service-error.js.map