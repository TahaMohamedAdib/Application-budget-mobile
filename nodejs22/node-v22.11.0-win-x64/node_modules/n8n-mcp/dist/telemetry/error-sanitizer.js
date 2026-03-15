"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.extractErrorMessage = extractErrorMessage;
exports.sanitizeStartupError = sanitizeStartupError;
exports.processStartupError = processStartupError;
const logger_1 = require("../utils/logger");
const error_sanitization_utils_1 = require("./error-sanitization-utils");
function extractErrorMessage(error) {
    try {
        if (error instanceof Error) {
            return error.stack || error.message || 'Unknown error';
        }
        if (typeof error === 'string') {
            return error;
        }
        if (error && typeof error === 'object') {
            const errorObj = error;
            if (errorObj.message) {
                return String(errorObj.message);
            }
            if (errorObj.error) {
                return String(errorObj.error);
            }
            try {
                return JSON.stringify(error).substring(0, 500);
            }
            catch {
                return 'Error object (unstringifiable)';
            }
        }
        return String(error);
    }
    catch (extractError) {
        logger_1.logger.debug('Error during message extraction:', extractError);
        return 'Error message extraction failed';
    }
}
function sanitizeStartupError(errorMessage) {
    return (0, error_sanitization_utils_1.sanitizeErrorMessageCore)(errorMessage);
}
function processStartupError(error) {
    const message = extractErrorMessage(error);
    return sanitizeStartupError(message);
}
//# sourceMappingURL=error-sanitizer.js.map