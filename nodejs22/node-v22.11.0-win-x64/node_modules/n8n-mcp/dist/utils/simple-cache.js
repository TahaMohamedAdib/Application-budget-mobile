"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SimpleCache = void 0;
class SimpleCache {
    constructor() {
        this.cache = new Map();
        this.cleanupTimer = null;
        this.cleanupTimer = setInterval(() => {
            const now = Date.now();
            for (const [key, item] of this.cache.entries()) {
                if (item.expires < now)
                    this.cache.delete(key);
            }
        }, 60000);
    }
    get(key) {
        const item = this.cache.get(key);
        if (!item || item.expires < Date.now()) {
            this.cache.delete(key);
            return null;
        }
        return item.data;
    }
    set(key, data, ttlSeconds = 300) {
        this.cache.set(key, {
            data,
            expires: Date.now() + (ttlSeconds * 1000)
        });
    }
    clear() {
        this.cache.clear();
    }
    destroy() {
        if (this.cleanupTimer) {
            clearInterval(this.cleanupTimer);
            this.cleanupTimer = null;
        }
        this.cache.clear();
    }
}
exports.SimpleCache = SimpleCache;
//# sourceMappingURL=simple-cache.js.map