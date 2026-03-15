import { DiffOperation } from '../types/workflow-diff.js';
import { IntentClassification } from './mutation-types.js';
export declare class IntentClassifier {
    classify(operations: DiffOperation[], userIntent?: string): IntentClassification;
    private classifyFromText;
    private classifyFromOperations;
    getConfidence(classification: IntentClassification, operations: DiffOperation[], userIntent?: string): number;
    getDescription(classification: IntentClassification): string;
}
export declare const intentClassifier: IntentClassifier;
//# sourceMappingURL=intent-classifier.d.ts.map