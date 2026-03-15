"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SSRFProtection = void 0;
const url_1 = require("url");
const promises_1 = require("dns/promises");
const logger_1 = require("./logger");
const CLOUD_METADATA = new Set([
    '169.254.169.254',
    '169.254.170.2',
    'metadata.google.internal',
    'metadata',
    '100.100.100.200',
    '192.0.0.192',
]);
const LOCALHOST_PATTERNS = new Set([
    'localhost',
    '127.0.0.1',
    '::1',
    '0.0.0.0',
    'localhost.localdomain',
]);
const PRIVATE_IP_RANGES = [
    /^10\./,
    /^192\.168\./,
    /^172\.(1[6-9]|2[0-9]|3[0-1])\./,
    /^169\.254\./,
    /^127\./,
    /^0\./,
];
class SSRFProtection {
    static async validateWebhookUrl(urlString) {
        try {
            const url = new url_1.URL(urlString);
            const mode = (process.env.WEBHOOK_SECURITY_MODE || 'strict');
            if (!['http:', 'https:'].includes(url.protocol)) {
                return { valid: false, reason: 'Invalid protocol. Only HTTP/HTTPS allowed.' };
            }
            let hostname = url.hostname.toLowerCase();
            if (hostname.startsWith('[') && hostname.endsWith(']')) {
                hostname = hostname.slice(1, -1);
            }
            if (CLOUD_METADATA.has(hostname)) {
                logger_1.logger.warn('SSRF blocked: Cloud metadata endpoint', { hostname, mode });
                return { valid: false, reason: 'Cloud metadata endpoint blocked' };
            }
            let resolvedIP;
            try {
                const { address } = await (0, promises_1.lookup)(hostname);
                resolvedIP = address;
                logger_1.logger.debug('DNS resolved for SSRF check', { hostname, resolvedIP, mode });
            }
            catch (error) {
                logger_1.logger.warn('DNS resolution failed for webhook URL', {
                    hostname,
                    error: error instanceof Error ? error.message : String(error)
                });
                return { valid: false, reason: 'DNS resolution failed' };
            }
            if (CLOUD_METADATA.has(resolvedIP)) {
                logger_1.logger.warn('SSRF blocked: Hostname resolves to cloud metadata IP', {
                    hostname,
                    resolvedIP,
                    mode
                });
                return { valid: false, reason: 'Hostname resolves to cloud metadata endpoint' };
            }
            if (mode === 'permissive') {
                logger_1.logger.warn('SSRF protection in permissive mode (localhost and private IPs allowed)', {
                    hostname,
                    resolvedIP
                });
                return { valid: true };
            }
            const isLocalhost = LOCALHOST_PATTERNS.has(hostname) ||
                resolvedIP === '::1' ||
                resolvedIP.startsWith('127.');
            if (mode === 'strict' && isLocalhost) {
                logger_1.logger.warn('SSRF blocked: Localhost not allowed in strict mode', {
                    hostname,
                    resolvedIP
                });
                return { valid: false, reason: 'Localhost access is blocked in strict mode' };
            }
            if (mode === 'moderate' && isLocalhost) {
                logger_1.logger.info('Localhost webhook allowed (moderate mode)', { hostname, resolvedIP });
                return { valid: true };
            }
            if (PRIVATE_IP_RANGES.some(regex => regex.test(resolvedIP))) {
                logger_1.logger.warn('SSRF blocked: Private IP address', { hostname, resolvedIP, mode });
                return {
                    valid: false,
                    reason: mode === 'strict'
                        ? 'Private IP addresses not allowed'
                        : 'Private IP addresses not allowed (use WEBHOOK_SECURITY_MODE=permissive if needed)'
                };
            }
            if (resolvedIP === '::1' ||
                resolvedIP === '::' ||
                resolvedIP.startsWith('fe80:') ||
                resolvedIP.startsWith('fc00:') ||
                resolvedIP.startsWith('fd00:') ||
                resolvedIP.startsWith('::ffff:')) {
                logger_1.logger.warn('SSRF blocked: IPv6 private address', {
                    hostname,
                    resolvedIP,
                    mode
                });
                return { valid: false, reason: 'IPv6 private address not allowed' };
            }
            return { valid: true };
        }
        catch (error) {
            return { valid: false, reason: 'Invalid URL format' };
        }
    }
}
exports.SSRFProtection = SSRFProtection;
//# sourceMappingURL=ssrf-protection.js.map