export interface AxelarBridgeData {
    moduleName: "crosschain";
    creditor: string;
    ipfsHash?: string;
    imageHash?: string;
}
export interface AxelarBridgeProps {
    currency: string;
    amount: number;
    module: AxelarBridgeData;
}
export declare function writeCrossChainNota({ module, amount, currency, }: AxelarBridgeProps): Promise<{
    txHash: string;
    notaId: string;
}>;
