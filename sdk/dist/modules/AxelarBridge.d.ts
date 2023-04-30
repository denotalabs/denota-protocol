export interface AxelarBridgeData {
    moduleName: "crosschain";
    creditor: string;
}
export interface AxelarBridgeProps {
    currency: string;
    amount: number;
    ipfsHash?: string;
    imageUrl?: string;
    module: AxelarBridgeData;
}
export declare function writeCrossChainNota({ module, amount, currency, imageUrl, ipfsHash, }: AxelarBridgeProps): Promise<{
    txHash: string;
    notaId: string;
}>;
