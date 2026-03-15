export declare const MINIMAL_WORKFLOW_EXAMPLE: {
    nodes: {
        name: string;
        type: string;
        typeVersion: number;
        position: number[];
        parameters: {
            httpMethod: string;
            path: string;
        };
    }[];
    connections: {};
};
export declare const SIMPLE_WORKFLOW_EXAMPLE: {
    nodes: ({
        name: string;
        type: string;
        typeVersion: number;
        position: number[];
        parameters: {
            httpMethod: string;
            path: string;
            mode?: undefined;
            assignments?: undefined;
            respondWith?: undefined;
        };
    } | {
        name: string;
        type: string;
        typeVersion: number;
        position: number[];
        parameters: {
            mode: string;
            assignments: {
                assignments: {
                    name: string;
                    type: string;
                    value: string;
                }[];
            };
            httpMethod?: undefined;
            path?: undefined;
            respondWith?: undefined;
        };
    } | {
        name: string;
        type: string;
        typeVersion: number;
        position: number[];
        parameters: {
            respondWith: string;
            httpMethod?: undefined;
            path?: undefined;
            mode?: undefined;
            assignments?: undefined;
        };
    })[];
    connections: {
        Webhook: {
            main: {
                node: string;
                type: string;
                index: number;
            }[][];
        };
        Set: {
            main: {
                node: string;
                type: string;
                index: number;
            }[][];
        };
    };
};
export declare function getWorkflowExampleString(): string;
//# sourceMappingURL=workflow-examples.d.ts.map