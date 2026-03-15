import { ValidationError, ValidationWarning } from './config-validator';
export interface NodeValidationContext {
    config: Record<string, any>;
    errors: ValidationError[];
    warnings: ValidationWarning[];
    suggestions: string[];
    autofix: Record<string, any>;
}
export declare class NodeSpecificValidators {
    static validateSlack(context: NodeValidationContext): void;
    private static validateSlackSendMessage;
    private static validateSlackUpdateMessage;
    private static validateSlackDeleteMessage;
    private static validateSlackCreateChannel;
    static validateGoogleSheets(context: NodeValidationContext): void;
    private static validateGoogleSheetsAppend;
    private static validateGoogleSheetsRead;
    private static validateGoogleSheetsUpdate;
    private static validateGoogleSheetsDelete;
    private static validateGoogleSheetsRange;
    static validateOpenAI(context: NodeValidationContext): void;
    static validateMongoDB(context: NodeValidationContext): void;
    static validatePostgres(context: NodeValidationContext): void;
    static validateAIAgent(context: NodeValidationContext): void;
    static validateMySQL(context: NodeValidationContext): void;
    private static validateSQLQuery;
    static validateHttpRequest(context: NodeValidationContext): void;
    static validateWebhook(context: NodeValidationContext): void;
    static validateCode(context: NodeValidationContext): void;
    private static validateJavaScriptCode;
    private static validatePythonCode;
    private static validateReturnStatement;
    private static validateN8nVariables;
    private static validateCodeSecurity;
    static validateSet(context: NodeValidationContext): void;
}
//# sourceMappingURL=node-specific-validators.d.ts.map