"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.detectBaseUrl = detectBaseUrl;
exports.getStartupBaseUrl = getStartupBaseUrl;
exports.formatEndpointUrls = formatEndpointUrls;
const logger_1 = require("./logger");
function isValidHostname(host) {
    return /^[a-zA-Z0-9.-]+(:[0-9]+)?$/.test(host) && host.length < 256;
}
function isValidUrl(url) {
    try {
        const parsed = new URL(url);
        return parsed.protocol === 'http:' || parsed.protocol === 'https:';
    }
    catch {
        return false;
    }
}
function detectBaseUrl(req, host, port) {
    try {
        const configuredUrl = process.env.BASE_URL || process.env.PUBLIC_URL;
        if (configuredUrl) {
            if (isValidUrl(configuredUrl)) {
                logger_1.logger.debug('Using configured BASE_URL/PUBLIC_URL', { url: configuredUrl });
                return configuredUrl.replace(/\/$/, '');
            }
            else {
                logger_1.logger.warn('Invalid BASE_URL/PUBLIC_URL configured, falling back to auto-detection', { url: configuredUrl });
            }
        }
        if (req && process.env.TRUST_PROXY && Number(process.env.TRUST_PROXY) > 0) {
            const proto = req.get('X-Forwarded-Proto') || req.protocol || 'http';
            const forwardedHost = req.get('X-Forwarded-Host');
            const hostHeader = req.get('Host');
            const detectedHost = forwardedHost || hostHeader;
            if (detectedHost && isValidHostname(detectedHost)) {
                const baseUrl = `${proto}://${detectedHost}`;
                logger_1.logger.debug('Detected URL from proxy headers', {
                    proto,
                    forwardedHost,
                    hostHeader,
                    baseUrl
                });
                return baseUrl;
            }
            else if (detectedHost) {
                logger_1.logger.warn('Invalid hostname detected in proxy headers, using fallback', { detectedHost });
            }
        }
        const displayHost = host === '0.0.0.0' ? 'localhost' : host;
        const protocol = 'http';
        const needsPort = port !== 80;
        const baseUrl = needsPort ?
            `${protocol}://${displayHost}:${port}` :
            `${protocol}://${displayHost}`;
        logger_1.logger.debug('Using fallback URL from host/port', {
            host,
            displayHost,
            port,
            baseUrl
        });
        return baseUrl;
    }
    catch (error) {
        logger_1.logger.error('Error detecting base URL, using fallback', error);
        return `http://localhost:${port}`;
    }
}
function getStartupBaseUrl(host, port) {
    return detectBaseUrl(null, host, port);
}
function formatEndpointUrls(baseUrl) {
    return {
        health: `${baseUrl}/health`,
        mcp: `${baseUrl}/mcp`,
        root: baseUrl
    };
}
//# sourceMappingURL=url-detector.js.map