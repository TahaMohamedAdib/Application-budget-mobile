import { DatabaseAdapter } from '../database/database-adapter';
export declare class SQLiteStorageService {
    private adapter;
    private dbPath;
    constructor(dbPath?: string);
    private initSync;
    private initializeSchema;
    get db(): DatabaseAdapter;
    close(): void;
}
//# sourceMappingURL=sqlite-storage-service.d.ts.map